; ----------------------------------------------------------------------
; File: nic_isr.asm
; Purpose: Interrupt Service Routine for the Network Interface Card (NIC)
; ----------------------------------------------------------------------

bits 32

; --- Constants for PIC (Programmable Interrupt Controller) ---
PIC_MASTER_CMD equ 0x20
PIC_SLAVE_CMD equ 0xA0
EOI equ 0x20             ; End of Interrupt command

; --- External Subroutines ---
; extern nic_driver_read_packet (Reads packet data from card's buffer)
; extern tcpip_input_handler (Processes the packet for the stack)
; extern nic_clear_interrupts (Resets the card's status register)

; ----------------------------------------------------------------------
; Subroutine: isr_nic_handler
; The Interrupt Service Routine registered for the NIC's IRQ line (e.g., IRQ 10/11)
; ----------------------------------------------------------------------
; NOTE: The CPU jumps here after pushing the EFLAGS, CS, and EIP to the stack.
isr_nic_handler:
    pushad                 ; Save general-purpose registers (EAX, ECX, etc.)
    
    ; 1. Check NIC Status and Clear Interrupts on the Card
    ; This is card-specific (e.g., reading the RTL8139 Interrupt Status Register)
    ; Determine if the interrupt was caused by a packet received (RX) or sent (TX)
    call nic_clear_interrupts ; Acknowledge the interrupt on the hardware itself

    ; 2. Handle Packet Reception
    ; If the card signaled a packet was received:
    
    ; Load the next packet from the card's ring buffer into a system buffer
    mov esi, [nic_receive_buffer_addr] 
    call nic_driver_read_packet ; Copies the packet from NIC to RAM buffer
    
    ; Pass the raw packet to the TCP/IP stack for processing
    push esi
    call tcpip_input_handler    ; ESI contains the raw Ethernet frame
    pop esi                     ; Balance the stack
    
    ; 3. Handle Packet Transmission Acknowledgment (TX)
    ; If the card signaled a transmission was completed:
    ; (This logic frees up the TX buffer slot for the next outgoing packet)
    
    ; 4. Send EOI (End of Interrupt) to the PIC
    ; This re-enables interrupts from the NIC's IRQ line.
    mov al, EOI
    out PIC_MASTER_CMD, al      ; Send to Master PIC
    ; If the IRQ is 8-15 (Slave PIC), also send EOI to the Slave PIC
    ; out PIC_SLAVE_CMD, al
    
    popad                      ; Restore general-purpose registers
    iret                       ; Return from interrupt (restores EIP, CS, EFLAGS)

; ----------------------------------------------------------------------
; Data (Needed by the driver to know where to find data)
nic_receive_buffer_addr dd 0 ; Address in RAM where the raw packet is stored
