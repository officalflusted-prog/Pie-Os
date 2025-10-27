; ----------------------------------------------------------------------
; File: input.asm
; Purpose: High-level Keyboard and Mouse Input Manager for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Data Section ---
kb_buffer times 128 db 0 ; Circular buffer for processed key codes
kb_head dw 0             ; Head pointer for the buffer
kb_tail dw 0             ; Tail pointer for the buffer

mouse_x dw 400           ; Current Mouse X position (center of 800x600)
mouse_y dw 300           ; Current Mouse Y position
mouse_buttons db 0       ; Button state (Bit 0: Left, Bit 1: Right)

; --- External Subroutines ---
; extern print_char (from lib.asm)

; ----------------------------------------------------------------------
; Subroutine: isr_keyboard_handler (Called by interrupts.asm's IRQ1 handler)
; Translates a raw scan code into a character and stores it in the buffer.
; ----------------------------------------------------------------------
isr_keyboard_handler:
    ; (This routine takes the raw scan code from port 0x60)
    ; 1. Check if the key is a release code (high bit set).
    ; 2. Use a look-up table (keymap) to convert the scan code to an ASCII character.
    ; 3. Handle modifier keys (Shift, Ctrl, Alt) to change the output character.
    ; 4. Store the final character in the 'kb_buffer'.
    ret

; ----------------------------------------------------------------------
; Subroutine: isr_mouse_handler (Needs PS/2 mouse initialization)
; Processes incoming mouse data packets (movement and buttons).
; ----------------------------------------------------------------------
isr_mouse_handler:
    ; (This routine is attached to IRQ 12, the secondary controller interrupt)
    ; 1. Read the 3-byte mouse data packet from the PS/2 port.
    ; 2. Update 'mouse_buttons' state.
    ; 3. Update 'mouse_x' and 'mouse_y' based on relative movement (delta-X, delta-Y).
    ; 4. Clamp mouse_x/y to screen boundaries (0 to 799, 0 to 599).
    ret

; ----------------------------------------------------------------------
; Subroutine: get_key
; Retrieves a single processed character from the keyboard buffer.
; ----------------------------------------------------------------------
; Returns: AX = ASCII character (or 0 if buffer is empty)
get_key:
    ; 1. Check if kb_head == kb_tail (buffer empty).
    ; 2. If not empty, read byte at kb_head, increment kb_head (circularly).
    ret

; ----------------------------------------------------------------------
; Subroutine: get_mouse_state
; Returns the current mouse position and button state.
; ----------------------------------------------------------------------
; Returns: AX = X, BX = Y, CL = Button State
get_mouse_state:
    mov ax, [mouse_x]
    mov bx, [mouse_y]
    mov cl, [mouse_buttons]
    ret
