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
    echo "Usage: ./masm.sh <source-file.asm|source-file.s> [--build-only|-b]"
    echo "Examples:"
    echo "  ./masm.sh main.asm        # Assemble, link, and run"
    echo "  ./masm.sh main.asm -b     # Build only (no run)"
    exit 1
fi

SRC_FILE="$1"
BUILD_ONLY=false
if [ "$2" == "--build-only" ] || [ "$2" == "-b" ]; then
    BUILD_ONLY=true
fi

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

echo "[1/2] Assembling $BASENAME..."
"$WINE_BIN" "$W_ML" /c /coff /I"$W_IRVINE" /Fo"$W_OBJ" "$W_SRC"

echo "[2/2] Linking $NAME.obj with Irvine32..."
"$WINE_BIN" "$W_LINK" /NOLOGO /SUBSYSTEM:CONSOLE /LIBPATH:"$W_IRVINE" Irvine32.lib Kernel32.Lib User32.Lib /OUT:"$W_EXE" "$W_OBJ"

if [ "$BUILD_ONLY" = true ]; then
    echo "Build succeeded: $EXE_FILE"
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
