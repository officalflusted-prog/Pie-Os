; ----------------------------------------------------------------------
; File: pmode_switch.asm
; Purpose: Transition from 16-bit Real Mode to 32-bit Protected Mode
; ----------------------------------------------------------------------

bits 16
; Assuming this file is loaded and executed from the kernel in Real Mode.

; --- External Subroutines ---
; extern print_string (from lib.asm)
; extern kernel_32bit_entry (The main function in your new 32-bit kernel)

; ----------------------------------------------------------------------
; Subroutine: switch_to_pmode
; Main routine to switch the CPU mode.
; ----------------------------------------------------------------------
switch_to_pmode:
    pusha
    
    cli                     ; 1. Disable Interrupts (critical before mode change)
    
    call setup_gdt          ; 2. Load the Global Descriptor Table (GDT)
    
    mov eax, cr0            ; 3. Set the PE (Protection Enable) bit in CR0
    or al, 0x01             ; Set the lowest bit of the CR0 register
    mov cr0, eax
    
    ; 4. Perform a FAR JUMP (Inter-Segment) to flush the pre-fetch queue
    ;    and load the new 32-bit CS (Code Segment) register
    jmp 0x08:.protected_mode_start
    
; ----------------------------------------------------------------------
; Subroutine: .protected_mode_start
; This is the code that executes immediately after the mode switch.
; ----------------------------------------------------------------------
bits 32
.protected_mode_start:
    ; 1. Set up 32-bit Data Segments
    mov ax, 0x10            ; Data Segment Selector (from GDT)
    mov ds, ax              ; Set DS, ES, FS, GS, SS to the data segment
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; 2. Set up a 32-bit Stack Pointer
    mov esp, 0x90000        ; Set the stack (e.g., at 576KB)
    
    ; 3. Jump to the 32-bit kernel entry point
    extern kernel_32bit_entry
    call kernel_32bit_entry ; Start the 32-bit kernel execution
    
    ; Fall through and halt if the kernel_32bit_entry returns
    jmp $

; ----------------------------------------------------------------------
; Subroutine: setup_gdt
; Sets up the GDT structure in memory and loads its address into the GDTR register.
; ----------------------------------------------------------------------
setup_gdt:
    ; 1. Define GDT structure in memory (e.g., 0x8000)
    mov edi, 0x8000
    
    ; Null Descriptor (Required first entry)
    mov dword [edi + 0x00], 0x00000000
    mov dword [edi + 0x04], 0x00000000
    
    ; Code Segment Descriptor (Selector 0x08)
    mov dword [edi + 0x08], 0x0000FFFF  ; Limit (0xFFFF), Base (0x0000)
    mov dword [edi + 0x0C], 0x00C09A00  ; Flags (4KB granularity, 32-bit, Present, Code/Readable)
    
    ; Data Segment Descriptor (Selector 0x10)
    mov dword [edi + 0x10], 0x0000FFFF
    mov dword [edi + 0x14], 0x00C09200  ; Flags (4KB granularity, 32-bit, Present, Data/Writable)
    
    ; 2. Load GDTR Register
    mov word [gdt_descriptor + 0], 23    ; GDT Limit (3 descriptors * 8 bytes - 1 = 23)
    mov dword [gdt_descriptor + 2], 0x8000 ; GDT Base Address
    lgdt [gdt_descriptor]
    
    ret

; ----------------------------------------------------------------------
; Data Section
; ----------------------------------------------------------------------
gdt_descriptor:
    dw 0
