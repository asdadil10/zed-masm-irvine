#!/usr/bin/env bash
set -e

echo "=== Zed x86 MASM + Irvine32 IntelliSense Installer ==="

# 1. Install language server binary
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
cp -f "$(dirname "$0")/masm-irvine-lsp" "$INSTALL_DIR/masm-irvine-lsp"
chmod +x "$INSTALL_DIR/masm-irvine-lsp"
echo "[✓] Installed masm-irvine-lsp to $INSTALL_DIR/masm-irvine-lsp"

# 2. Configure Zed settings.json
ZED_SETTINGS="$HOME/.config/zed/settings.json"
mkdir -p "$(dirname "$ZED_SETTINGS")"

python3 - << 'EOF'
import json
import os
import sys

settings_path = os.path.expanduser("~/.config/zed/settings.json")
data = {}
if os.path.exists(settings_path):
    try:
        # Strip comments if any or simple load
        import re
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
data["lsp"]["asm-lsp"] = {
    "binary": {
        "path": os.path.expanduser("~/.local/bin/masm-irvine-lsp")
    }
}

# Ensure file associations
if "file_types" not in data:
    data["file_types"] = {}
if "Assembly" not in data["file_types"]:
    data["file_types"]["Assembly"] = ["asm", "s", "S", "inc"]

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)

print("[✓] Updated ~/.config/zed/settings.json with MASM & Irvine32 LSP integration")
EOF

echo ""
echo "Installation complete! Restart Zed or open any .asm file to enjoy:"
echo "  • Full Irvine32 procedure autocompletion and hover docs (WriteString, ReadInt, DumpRegs, etc.)"
echo "  • x86 instruction reference with operand rules and CPU flags (mov, add, cmp, loop, etc.)"
echo "  • x86 registers reference with roles (eax, edx, ecx, etc.)"
echo "  • Dynamic user symbols (variables, labels, procedures) autocompletion and Go-to-Definition"
