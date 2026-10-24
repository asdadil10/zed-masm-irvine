#!/usr/bin/env bash
set -e

echo "=== Zed x86 MASM + Irvine32 IntelliSense Installer ==="

# 1. Install binaries to user local bin
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install LSP server
rm -f "$INSTALL_DIR/masm-irvine-lsp"
cp -f "$SCRIPT_SOURCE_DIR/masm-irvine-lsp" "$INSTALL_DIR/masm-irvine-lsp"
chmod +x "$INSTALL_DIR/masm-irvine-lsp"
echo "[✓] Installed masm-irvine-lsp to $INSTALL_DIR/masm-irvine-lsp"

# Install masm.sh build runner
if [ -f "$SCRIPT_SOURCE_DIR/masm.sh" ]; then
    rm -f "$INSTALL_DIR/masm.sh"
    cp -f "$SCRIPT_SOURCE_DIR/masm.sh" "$INSTALL_DIR/masm.sh"
    chmod +x "$INSTALL_DIR/masm.sh"
    echo "[✓] Installed masm.sh to $INSTALL_DIR/masm.sh"
fi

# 2. Configure Zed settings.json
ZED_SETTINGS="${HOME}/.config/zed/settings.json"
mkdir -p "$(dirname "$ZED_SETTINGS")"

python3 - << 'EOF'
import json
import os
import re

home = os.environ.get("HOME", os.path.expanduser("~"))
settings_path = os.path.join(home, ".config", "zed", "settings.json")
data = {}

if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r') as f:
            content = f.read()
        # Remove single line comments
        clean = re.sub(r'//.*', '', content)
        data = json.loads(clean)
    except Exception as e:
        print(f"[!] Note: Could not parse existing settings.json ({e}). Creating backup.")
        os.system(f"cp {settings_path} {settings_path}.bak")
        data = {}

# Ensure auto_install_extensions
if "auto_install_extensions" not in data:
    data["auto_install_extensions"] = {}
data["auto_install_extensions"]["assembly"] = True

# Ensure lsp configuration
if "lsp" not in data:
    data["lsp"] = {}

lsp_bin_path = os.path.join(home, ".local", "bin", "masm-irvine-lsp")
data["lsp"]["asm-lsp"] = {
    "binary": {
        "path": lsp_bin_path
    }
}

# Ensure file associations
if "file_types" not in data:
    data["file_types"] = {}
if "Assembly" not in data["file_types"]:
    data["file_types"]["Assembly"] = ["asm", "s", "S", "inc"]

# Ensure formatting on save for Assembly
data["format_on_save"] = "on"
if "languages" not in data:
    data["languages"] = {}
if "Assembly" not in data["languages"]:
    data["languages"]["Assembly"] = {}
data["languages"]["Assembly"]["tab_size"] = 4
data["languages"]["Assembly"]["hard_tabs"] = False
data["languages"]["Assembly"]["format_on_save"] = "on"
data["languages"]["Assembly"]["formatter"] = "language_server"

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)

print("[✓] Updated ~/.config/zed/settings.json with MASM & Irvine32 LSP integration")
EOF

echo ""
echo "Installation complete! Restart Zed or open any .asm file to enjoy:"
echo "  • Full Irvine32 procedure autocompletion and hover docs (WriteString, ReadInt, DumpRegs, etc.)"
echo "  • Real-time semantic diagnostics & data-flow hazard linter (EAX/EDX clobbers, loop counter traps)"
echo "  • 1-Click Code Action quick-fixes (Alt+Enter for instant repairs)"
echo "  • Canonical 4-column MASM auto-formatter on save (Ctrl+S)"
echo "  • Interactive step-debugging with WineDbg (masm.sh -d or Zed task)"
echo "  • x86 instruction & register reference tooltips"
echo "  • masm.sh executable runner available at ~/.local/bin/masm.sh"
