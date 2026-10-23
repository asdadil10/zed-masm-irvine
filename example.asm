TITLE Test Irvine32 Program in Zed
INCLUDE Irvine32.inc

.data
    promptMsg    BYTE "Enter a positive integer: ", 0
    resultMsg    BYTE "You entered: ", 0
    byeMsg       BYTE "Exiting program. Goodbye!", 0
    userInput    DWORD ?

.code
main PROC
    ; Clear the console screen
    call Clrscr

    ; Change text color: yellow text on blue background
    mov eax, yellow + (lightRed * 16)
    call SetTextColor

    ; Position cursor at row 5, col 10
    mov dh, 5
    mov dl, 10
    call Gotoxy

    ; Prompt user
    mov edx, OFFSET promptMsg
    call WriteString

    ; Read signed 32-bit integer into EAX
    call ReadInt
    mov userInput, eax

    ; Print newline
    call Crlf

    ; Display result
    mov edx, OFFSET resultMsg
    call WriteString

    mov eax, userInput
    call WriteInt
    call Crlf

    ; Display CPU registers dump
    call Crlf
    call DumpRegs
    call Crlf

    ; Say goodbye
    mov edx, OFFSET byeMsg
    call WriteString
    call Crlf

    ; Pause before exiting
    call WaitMsg
    exit
main ENDP
END main
