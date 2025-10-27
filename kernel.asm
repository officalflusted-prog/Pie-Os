; ----------------------------------------------------------------------
; File: kernel.asm
; Purpose: The simple 16-bit Real Mode kernel for PieOS
; ----------------------------------------------------------------------

; NOTE: The bootloader will load this kernel somewhere *after* 0x7E00.
; For simplicity, we'll assume it's loaded at 0x10000 (1MB) later,
; but for now, we'll just focus on the code structure.

bits 16         ; Still in 16-bit Real Mode

; --- Start of Code ---

start:
    ; 1. Set up Segments
    ; The bootloader left us in a messy state. Set all segment registers.
    xor ax, ax
    mov ds, ax      ; Data Segment (DS)
    mov es, ax      ; Extra Segment (ES)
    mov ss, ax      ; Stack Segment (SS)
    mov sp, 0xFFFF  ; Set Stack Pointer (SP) high in the segment

    ; 2. Print a "Kernel Loaded" message
    mov si, kernel_msg  ; Load the address of the message

.print_loop:
    lodsb           ; Load byte at [SI] into AL, then increment SI
    cmp al, 0       ; Compare AL (the character) with 0 (null-terminator)
    je .done        ; If AL is zero, we are done

    ; Use BIOS interrupt to display the character
    mov ah, 0x0e    ; Function 0Eh: write character in TTY mode
    mov bx, 0x0002  ; Page number (BH=0), Attribute (BL=2, green)
    int 0x10        ; Call BIOS video interrupt

    jmp .print_loop ; Loop back

.done:
    ; 3. The Kernel's Job is done for now: Hang the system
    cli             ; Clear Interrupts (disable interrupts)
    hlt             ; Halt the CPU

; --- Data Section ---
kernel_msg db "PieOS Kernel Loaded. System Halted.", 0x0d, 0x0a, 0x00

; --- Kernel Size Marker ---
; We don't need a signature like the boot sector, but we should make
; sure the kernel is large enough to be loaded from disk.
; For simplicity, we'll just end it here.
