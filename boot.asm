; ----------------------------------------------------------------------
; File: boot.asm
; Purpose: The 512-byte boot sector for PieOS (Real Mode)
; ----------------------------------------------------------------------

bits 16         ; Tell the assembler to generate 16-bit code (Real Mode)
org 0x7c00      ; Tell the assembler where the code will be loaded into memory by the BIOS

; --- Start of Code ---

; 1. Clear the screen (optional, but good practice)
xor ax, ax      ; Set AX register to 0
mov es, ax      ; Set Extra Segment (ES) register to 0 (for video memory access)
mov ah, 0x07    ; Function 07h: scroll window
mov al, 0x00    ; Scroll full window
mov bh, 0x07    ; Attribute: light gray on black (0x07)
mov cx, 0x0000  ; Top left corner (row 0, col 0)
mov dx, 0x184f  ; Bottom right corner (row 24, col 79)
int 0x10        ; BIOS video interrupt

; 2. Print a simple message to the screen
mov si, boot_msg  ; Load the address of the message into Source Index (SI) register

.print_loop:
    lodsb         ; Load byte at [SI] into AL, then increment SI
    cmp al, 0     ; Compare AL (the character) with 0 (null-terminator)
    je .done      ; If AL is zero, we are done

    ; Use BIOS interrupt to display the character
    mov ah, 0x0e  ; Function 0Eh: write character in TTY mode
    mov bx, 0x0007; Page number (BH=0), Attribute (BL=7, light gray)
    int 0x10      ; Call BIOS video interrupt

    jmp .print_loop ; Loop back

.done:
    ; 3. Hang the system (Since we have no kernel yet, just stop here)
    cli             ; Clear Interrupts (disable interrupts)
    hlt             ; Halt the CPU

; --- Data Section ---
boot_msg db "Booting PieOS... Hello World!", 0x0d, 0x0a, 0x00 ; Message (CR, LF, Null-terminator)

; --- Padding and Signature ---
; Pad the rest of the 512 bytes with zeros
times 510 - ($ - $$) db 0

; The Boot Signature: Must be the last two bytes of the 512-byte sector
dw 0xaa55
