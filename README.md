# Zed x86 MASM + Irvine32 IntelliSense Extension & Toolchain

Full Language Server Protocol (LSP), IntelliSense support, and build automation for **x86 MASM Assembly** and **Kip Irvine's Irvine32 library** inside the **Zed editor**.

---

## The Problem with Default Zed Assembly

The official community Zed extension (`assembly` / `DevBlocky/zed-asm`) connects to `asm-lsp`. However:
1. **`asm-lsp` targets GAS and NASM on Linux** by running `gcc` or `clang` checks behind the scenes.
2. It **does not recognize Irvine32 procedures or macros** (`WriteString`, `ReadInt`, `Clrscr`, `DumpRegs`, `mWrite`, etc.).
3. It gives **no input/output parameter hints** (e.g. that `EDX` must hold `OFFSET string` before `call WriteString`, or that `ReadInt` returns its integer in `EAX`).
4. It does not index user-defined variables or labels in `.data` and `.code`.

---

## What This Solution Provides

This extension & language server (`masm-irvine-lsp`) gives Zed native IntelliSense tailored specifically for MASM and Irvine32:

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

### 6. 1-Click Code Actions & Quick-Fixes (`Alt+Enter`)
Provides automated 1-click repairs for compiler and linter diagnostics directly in Zed via the quick-fix lightbulb (`Alt+Enter`):
* 💡 **Insert 'OFFSET' operator:** Automatically fixes `mov edx, myMsg` into `mov edx, OFFSET myMsg`.
* 💡 **Append null terminator (', 0'):** Automatically adds `, 0` to un-terminated byte strings in `.data`.
* 💡 **Insert 'exit' before ENDP:** Automatically inserts `exit` statement before procedure end.
* 💡 **Convert to zero-extending 'movzx':** Automatically fixes register/operand width mismatches.
* 💡 **Specify 'DWORD PTR' / 'BYTE PTR':** Automatically qualifies ambiguous memory dereferences.

### 7. Opinionated 4-Column MASM Formatter (`Ctrl+S` / Format Document)
Automatically beautifies and aligns code into textbook standard layout:
* **Margin 0:** Labels, Segment Directives (`.data`, `.code`), Procedure definitions (`main PROC`, `ENDP`), and `INCLUDE` / `TITLE` / `END`.
* **Column 4:** Instructions (`mov`, `call`, `add`) and data directives (`BYTE`, `DWORD`).
* **Column 16:** Operands (`edx, OFFSET myMsg`, `eax, 5`), with operators like `OFFSET` and `PTR` cleanly capitalized.
* **Column 48:** Trailing comments (`; ...`), uniformly aligned.

### 8. Portable Assembler & Runner Script (`masm.sh`)
* Automatically discovers `masm_tools` and Wine runtime dynamically (including Proton or system Wine) with zero hardcoded paths.
* Supports both assemble-link-and-run and build-only modes:
  ```bash
  masm.sh program.asm         # Assemble, link, and run
  masm.sh program.asm -b      # Build only (generates .exe)
  ```
* Preserves and displays compiler and linker errors with syntax line numbers.

### 7. Instant Code Snippet
* Typing `template-irvine32` generates a complete, clean MASM + Irvine32 program skeleton ready to build.

---

## Installation

### Method 1: Automatic 1-Click Installer (Recommended)

Run the included installer from the project repository:
```bash
./install.sh
```
This automatically:
1. Installs `masm-irvine-lsp` and `masm.sh` to `${HOME}/.local/bin/`.
2. Updates `~/.config/zed/settings.json` with the required LSP mapping and syntax associations.

### Method 2: Manual Setup

1. Copy the binaries to your local bin path:
   ```bash
   mkdir -p ~/.local/bin
   cp masm-irvine-lsp masm.sh ~/.local/bin/
   chmod +x ~/.local/bin/masm-irvine-lsp ~/.local/bin/masm.sh
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
           "path": "~/.local/bin/masm-irvine-lsp"
         }
       }
     },
     "file_types": {
       "Assembly": ["asm", "s", "S", "inc"]
     }
   }
   ```

---

## 1-Click Zed Build & Run Task Setup

You can configure Zed to compile and run your active MASM file with a single keystroke.

### Step 1: Create a Workspace Task

Create or open `.zed/tasks.json` in your workspace root (e.g. inside your `COAL` project directory):

```json
[
  {
    "label": "MASM: Build & Run",
    "command": "masm.sh",
    "args": ["$ZED_FILE"],
    "use_new_terminal": false,
    "allow_concurrent_runs": false,
    "reveal": "always"
  },
  {
    "label": "MASM: Build Only",
    "command": "masm.sh",
    "args": ["$ZED_FILE", "-b"],
    "use_new_terminal": false,
    "allow_concurrent_runs": false,
    "reveal": "always"
  }
]
```

### Step 2: Triggering the Task

* **Via Command Palette:** Press `Ctrl+Shift+P` -> search **`task: spawn`** -> select `MASM: Build & Run`.
* **Optional Keybinding:** In your Zed `keymap.json` (`~/.config/zed/keymap.json`), you can bind `Ctrl+R` to run the task whenever an assembly file is open:
  ```json
  [
    {
      "context": "Editor && (extension == asm || extension == s || extension == inc)",
      "bindings": {
        "ctrl-r": ["task::Spawn", { "task_name": "MASM: Build & Run" }]
      }
    }
  ]
  ```
