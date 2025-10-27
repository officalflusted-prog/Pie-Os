; ----------------------------------------------------------------------
; File: interrupts.asm
; Purpose: Interrupt Descriptor Table (IDT) and Interrupt Service Routines (ISRs) for PieOS
; ----------------------------------------------------------------------

bits 16

; --- 1. IDT Structure Definition ---
; For Real Mode, we use the IVT (Interrupt Vector Table) at 0x0000:0x0000.
; For Protected Mode, we would define the IDT, but let's stick to IVT for now.

; NOTE: The kernel will need to SET the IVT entries. This file defines the handlers.

; --- 2. Timer Interrupt Handler (IRQ 0) ---
; The timer interrupt occurs about 18.2 times per second.

timer_isr:
    pusha                   ; Save all registers
    
    ; Increment the global system tick counter (a variable defined in the kernel)
    ; inc [system_ticks]

    ; Example: Simple task switch or a print statement for debugging
    ; We'll just acknowledge the interrupt for now.

    mov al, 0x20            ; EOI (End of Interrupt) command
    out 0x20, al            ; Send EOI to the PIC (Primary Interrupt Controller)

    popa                    ; Restore all registers
    iret                    ; Return from interrupt (Pops IP, CS, Flags)

; --- 3. Keyboard Interrupt Handler (IRQ 1) ---
keyboard_isr:
    pusha                   ; Save all registers

    ; 1. Read the scan code from the keyboard controller
    in al, 0x60             ; Read data from port 0x60 (Keyboard Data Port)
    
    ; 2. Process the key (e.g., store it in a keyboard buffer)
    ; mov [key_buffer], al  ; (Requires a buffer variable)
    
    ; 3. Acknowledge the interrupt
    mov al, 0x20            ; EOI (End of Interrupt) command
    out 0x20, al            ; Send EOI to the PIC

    popa                    ; Restore all registers
    iret                    ; Return from interrupt

; --- More Handlers Go Here (e.g., Disk Interrupt, General Protection Fault) ---

; ----------------------------------------------------------------------
; Subroutine: pic_setup
; Initializes the Programmable Interrupt Controller (PIC)
; The kernel must CALL this function after loading.
; ----------------------------------------------------------------------
pic_setup:
    pusha
    
    ; Start initialization sequence for the PIC (Master & Slave)
    ; Send ICW1 (Initialization Control Word 1)
    mov al, 0x11
    out 0x20, al            ; Master PIC (port 0x20)
    out 0xA0, al            ; Slave PIC (port 0xA0)

    ; Send ICW2 (Master PIC vector offset: 0x20-0x27)
    mov al, 0x20            ; Map IRQ 0-7 to interrupt vectors 0x20-0x27
    out 0x21, al

    ; Send ICW2 (Slave PIC vector offset: 0x28-0x2F)
    mov al, 0x28            ; Map IRQ 8-15 to interrupt vectors 0x28-0x2F
    out 0xA1, al

    ; Send ICW3 (Wiring: Master connected to Slave on IRQ 2)
    mov al, 0x04            ; Master has slave on IRQ 2 (bit 2 = 1)
    out 0x21, al
    mov al, 0x02            ; Slave is connected to Master on its IRQ 2
    out 0xA1, al

    ; Send ICW4 (Mode: 8086 mode)
    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; Set the initial mask (Enable/Disable specific IRQs)
    mov al, 0xFC            ; Mask all but IRQ 0 (Timer) and IRQ 1 (Keyboard)
    out 0x21, al            ; Master mask
    mov al, 0xFF            ; Mask all slave IRQs for now
    out 0xA1, al            ; Slave mask

    popa
    ret
