# Zed x86 MASM + Irvine32 IntelliSense Extension & Language Server

Full Language Server Protocol (LSP) and IntelliSense support for **x86 MASM Assembly** and **Kip Irvine's Irvine32 library** inside the **Zed editor**.

---

## The Problem with Default Zed Assembly

The official community Zed extension (`assembly` / `DevBlocky/zed-asm`) connects to `asm-lsp`. However:
1. **`asm-lsp` targets GAS and NASM on Linux** by running `gcc` or `clang` checks behind the scenes.
2. It **does not recognize Irvine32 procedures or macros** (`WriteString`, `ReadInt`, `Clrscr`, `DumpRegs`, `mWrite`, etc.).
3. It gives **no input/output parameter hints** (e.g. that `EDX` must hold `OFFSET string` before `call WriteString`, or that `ReadInt` returns its integer in `EAX`).
4. It does not index user-defined variables or labels in the `.data` and `.code` sections.

---

## What This Solution Provides

This extension & language server (`masm-irvine-lsp`) gives Zed full native IntelliSense tailored specifically for MASM and Irvine32:

### 1. Complete Irvine32 Procedure IntelliSense
* Autocompletes and provides detailed hover tooltips with Markdown documentation, required input/output registers, and code examples for all Irvine32 routines:
  * **String & Char I/O:** `WriteString`, `ReadString`, `WriteChar`, `ReadChar`, `Crlf`, `Clrscr`
  * **Numeric I/O:** `WriteInt`, `ReadInt`, `WriteDec`, `ReadDec`, `WriteHex`, `WriteHexB`, `ReadHex`, `WriteBin`, `WriteBinB`
  * **System & Diagnostics:** `DumpRegs`, `DumpMem`, `WaitMsg`, `GetMseconds`, `Delay`
  * **Screen & Text Attributes:** `Gotoxy`, `SetTextColor`, `GetTextColor`
  * **Random Numbers:** `Randomize`, `RandomRange`, `Random32`
  * **String Manipulation:** `Str_length`, `Str_compare`, `Str_copy`, `Str_ucase`, `Str_trim`
  * **Windows GUI & Files:** `MsgBox`, `MsgBoxAsk`, `OpenInputFile`, `ReadFromFile`, `WriteToFile`

### 2. Irvine32 Macros & Color Constants
* Macros: `mWrite`, `mWriteLn`, `mReadString`, `mGotoxy`, `mDumpMem`
* Colors: `black`, `blue`, `green`, `cyan`, `red`, `magenta`, `brown`, `lightGray`, `gray`, `lightBlue`, `lightGreen`, `lightCyan`, `lightRed`, `lightMagenta`, `yellow`, `white`

### 3. Full x86 Register & Instruction Reference
* Hovering over any register (`EAX`, `EDX`, `ECX`, `ESI`, `EBX`, `AL`, `DH`, etc.) explains its architectural role and typical conventions.
* Hovering over instructions (`mov`, `add`, `sub`, `cmp`, `loop`, `jmp`, `idiv`, `lea`, etc.) shows syntax, operand constraints, and affected CPU status flags (`CF`, `ZF`, `SF`, `OF`).

### 4. Live User Symbol Autocompletion & Go-to-Definition
* Parses your active document in real time:
  * **Procedures:** `main PROC` -> autocompletes and jumps to procedure definition (`gd`).
  * **Variables:** `myMsg BYTE "Hello", 0` or `val DWORD ?` -> autocompletes with type/value hints, prioritized when typing after `OFFSET`.
  * **Labels:** `L1:` -> autocompletes with jump instructions (`jmp`, `je`, `jne`, `loop`).
  * **Constants:** `BUFFER_SIZE = 100` or `MAX EQU 50`.

### 5. Real-Time Semantic Diagnostics & Linter (Irvine32-Aware)
Catches common assembly pitfalls directly inside Zed as you type:
* **Missing `OFFSET` Warning (`Irvine-001`):** Flags when moving a string variable into `EDX` without `OFFSET` before calling string procedures like `WriteString`.
* **Unterminated String Warning (`Irvine-002`):** Warns if a string declaration in `.data` is missing its terminating `, 0` when passed to `WriteString`.
* **Operand Size Mismatch (`MASM-001`):** Flags mismatched bit-widths in instructions (e.g. `mov al, eax`, `add bx, edx`, or mismatch between register and declared variable type).
* **Missing `exit` before `ENDP` (`Irvine-003`):** Warns if `main PROC` does not call `exit` or `ExitProcess` before `main ENDP`, preventing runaway execution into adjacent memory.
* **Ambiguous Memory Operand (`MASM-002`):** Warns on ambiguous dereferences like `mov [esi], 5` requiring `BYTE PTR`, `WORD PTR`, or `DWORD PTR`.
* **Undefined Jump Label (`MASM-003`):** Flags jumps or loops targeting labels that do not exist.

### 6. Instant Code Snippet
* Typing `template-irvine32` generates a complete, clean MASM + Irvine32 program skeleton ready to build.

---

## Installation

### Method 1: Automatic 1-Click Script (Recommended)

Run the included installer:
```bash
cd /home/adil/.gemini/antigravity/scratch/zed-masm-irvine
./install.sh
```

### Method 2: Manual Setup

1. Copy `masm-irvine-lsp` into your path:
   ```bash
   cp masm-irvine-lsp ~/.local/bin/
   chmod +x ~/.local/bin/masm-irvine-lsp
   ```

2. Open your Zed settings (`Ctrl+,` or `~/.config/zed/settings.json`) and add:
   ```json
   {
     "auto_install_extensions": {
       "assembly": true
     },
     "lsp": {
       "asm-lsp": {
         "binary": {
           "path": "/home/adil/.local/bin/masm-irvine-lsp"
         }
       }
     },
     "file_types": {
       "Assembly": ["asm", "s", "S", "inc"]
     }
   }
   ```

3. Open any `.asm` file in Zed!
