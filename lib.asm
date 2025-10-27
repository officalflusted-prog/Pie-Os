; ----------------------------------------------------------------------
; File: lib.asm
; Purpose: Reusable functions (subroutines) for PieOS (16-bit Real Mode)
; ----------------------------------------------------------------------

; NOTE: This file is NOT assembled into a boot sector or kernel. It is
; typically included (or linked) into the kernel/program code.

; ----------------------------------------------------------------------
; Subroutine: print_string
; Prints a null-terminated string to the screen using BIOS int 10h.
;
; Parameters:
;   SI: Address of the null-terminated string (must be set by the caller)
;   BX: Display configuration (BH=Page, BL=Attribute) (e.g., 0x0007 for gray)
; ----------------------------------------------------------------------
print_string:
    pusha           ; Save all general-purpose registers (best practice)

.print_loop:
    lodsb           ; Load byte at [SI] into AL, then increment SI
    cmp al, 0       ; Compare AL (the character) with 0 (null-terminator)
    je .done        ; If AL is zero, we are done

    ; Call BIOS interrupt to display the character
    mov ah, 0x0e    ; Function 0Eh: write character in TTY mode
    int 0x10        ; Call BIOS video interrupt

    jmp .print_loop ; Loop back

.done:
    popa            ; Restore all general-purpose registers
    ret             ; Return to the caller

; ----------------------------------------------------------------------
; Subroutine: clear_screen
; Clears the entire screen using BIOS int 10h (Function 07h).
;
; Parameters:
;   BH: Attribute (Color) for the new screen (e.g., 0x07 for light gray)
; ----------------------------------------------------------------------
clear_screen:
    pusha           ; Save all general-purpose registers

    mov ah, 0x07    ; Function 07h: scroll window
    mov al, 0x00    ; Scroll full window
    ; BH is passed by the caller
    mov cx, 0x0000  ; Top left corner (row 0, col 0)
    mov dx, 0x184f  ; Bottom right corner (row 24, col 79)
    int 0x10        ; BIOS video interrupt

    popa            ; Restore all general-purpose registers
    ret             ; Return to the caller

; --- More Subroutines Go Here (e.g., read_key, newline, disk_read) ---
