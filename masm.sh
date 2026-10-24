#!/usr/bin/env bash
set -e

# Resolve script directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find masm_tools directory dynamically
TOOLS_DIR=""
CANDIDATE_TOOLS_DIRS=(
    "${MASM_TOOLS_DIR:-}"
    "$SCRIPT_DIR/masm_tools"
    "${HOME}/COAL/masm_tools"
    "${HOME}/masm_tools"
    "${HOME}/.local/share/masm_tools"
)

for d in "${CANDIDATE_TOOLS_DIRS[@]}"; do
    if [ -n "$d" ] && [ -d "$d/bin" ]; then
        TOOLS_DIR="$d"
        break
    fi
done

if [ -z "$TOOLS_DIR" ]; then
    echo "Error: masm_tools directory not found!"
    echo "Checked locations:"
    for d in "${CANDIDATE_TOOLS_DIRS[@]}"; do
        [ -n "$d" ] && echo "  - $d"
    done
    exit 1
fi

# Detect Irvine directory dynamically (handles nested Irvine/Irvine or Irvine)
IRVINE_DIR=""
if [ -d "$TOOLS_DIR/Irvine/Irvine" ]; then
    IRVINE_DIR="$TOOLS_DIR/Irvine/Irvine"
elif [ -d "$TOOLS_DIR/Irvine" ]; then
    IRVINE_DIR="$TOOLS_DIR/Irvine"
else
    echo "Error: Irvine directory not found in $TOOLS_DIR!"
    exit 1
fi

BIN_DIR="$TOOLS_DIR/bin"
PREFIX_DIR="${WINEPREFIX:-$TOOLS_DIR/wineprefix}"

# Find Wine binary dynamically without hardcoded paths
WINE_BIN=""
WINE_CANDIDATES=(
    "${WINE:-}"
    "$(which wine 2>/dev/null || true)"
)

# Search Proton in user Steam paths dynamically
while IFS= read -r proton_wine; do
    if [ -n "$proton_wine" ] && [ -x "$proton_wine" ]; then
        WINE_CANDIDATES+=("$proton_wine")
    fi
done < <(find "${HOME}/.local/share/Steam/compatibilitytools.d" "${HOME}/.steam/root/compatibilitytools.d" -maxdepth 4 -name "wine" -type f -executable 2>/dev/null || true)

for candidate in "${WINE_CANDIDATES[@]}"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        WINE_BIN="$candidate"
        break
    fi
done

if [ -z "$WINE_BIN" ]; then
    echo "Error: Wine binary not found on your system."
    echo "Please install Wine or set WINE environment variable (e.g. export WINE=/path/to/wine)."
    exit 1
fi

export WINEDEBUG=-all,err-all,fixme-all
export WINEPREFIX="$PREFIX_DIR"

if [ -z "$1" ]; then
    echo "Usage: ./masm.sh <source-file.asm|source-file.s> [--build-only|-b] [--debug|-d]"
    echo "Examples:"
    echo "  ./masm.sh main.asm        # Assemble, link, and run"
    echo "  ./masm.sh main.asm -b     # Build only (no run)"
    echo "  ./masm.sh main.asm -d     # Assemble with debug symbols & start WineDbg"
    exit 1
fi

SRC_FILE="$1"
shift
BUILD_ONLY=false
DEBUG_MODE=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-only|-b)
            BUILD_ONLY=true
            ;;
        --debug|-d)
            DEBUG_MODE=true
            ;;
        *)
            ;;
    esac
    shift
done

if [ ! -f "$SRC_FILE" ]; then
    echo "Error: File '$SRC_FILE' not found."
    exit 1
fi

# Get absolute path and base name
SRC_ABS="$(realpath "$SRC_FILE")"
BASENAME="$(basename "$SRC_FILE")"
DIRNAME="$(dirname "$SRC_ABS")"
NAME="${BASENAME%.*}"

OBJ_FILE="$DIRNAME/$NAME.obj"
EXE_FILE="$DIRNAME/$NAME.exe"

# Convert Unix path to Wine Z:\ drive path
to_wine_path() {
    echo "Z:${1//\//\\}"
}

W_SRC="$(to_wine_path "$SRC_ABS")"
W_OBJ="$(to_wine_path "$OBJ_FILE")"
W_EXE="$(to_wine_path "$EXE_FILE")"
W_IRVINE="$(to_wine_path "$IRVINE_DIR")"
W_ML="$(to_wine_path "$BIN_DIR/ml.exe")"
W_LINK="$(to_wine_path "$BIN_DIR/link.exe")"

ML_FLAGS="/c /coff"
LINK_FLAGS="/NOLOGO /SUBSYSTEM:CONSOLE"

if [ "$DEBUG_MODE" = true ]; then
    ML_FLAGS="$ML_FLAGS /Zi"
    LINK_FLAGS="$LINK_FLAGS /DEBUG"
fi

echo "[1/2] Assembling $BASENAME..."
"$WINE_BIN" "$W_ML" $ML_FLAGS /I"$W_IRVINE" /Fo"$W_OBJ" "$W_SRC"

echo "[2/2] Linking $NAME.obj with Irvine32..."
"$WINE_BIN" "$W_LINK" $LINK_FLAGS /LIBPATH:"$W_IRVINE" Irvine32.lib Kernel32.Lib User32.Lib /OUT:"$W_EXE" "$W_OBJ"

if [ "$BUILD_ONLY" = true ]; then
    echo "Build succeeded: $EXE_FILE"
    exit 0
fi

if [ "$DEBUG_MODE" = true ]; then
    echo "=================================================="
    echo "Starting WineDbg interactive debugger for $NAME.exe"
    echo "Debugger Commands Cheatsheet:"
    echo "  b *main         : Set breakpoint at main procedure"
    echo "  c (cont)        : Continue running until breakpoint or crash"
    echo "  s (step)        : Step into source line"
    echo "  n (next)        : Step over source line"
    echo "  si (stepi)      : Step one machine instruction"
    echo "  info registers  : Inspect EAX, EBX, ECX, EDX, ESI, EDI, ESP, EBP, EFLAGS"
    echo "  x/4x \$esp       : Examine memory at stack pointer"
    echo "  q (quit)        : Exit debugger"
    echo "=================================================="
    "$WINE_BIN" winedbg "$W_EXE"
    exit 0
fi

echo "Running $NAME.exe:"
echo "--------------------------------------------------"
set +e
"$WINE_BIN" "$W_EXE"
EXIT_CODE=$?
set -e
echo ""
echo "--------------------------------------------------"
echo "Program finished with exit code: $EXIT_CODE"
