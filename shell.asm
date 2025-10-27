; ----------------------------------------------------------------------
; File: shell.asm
; Purpose: The primary Command Shell (or 'Desktop Manager') for PieOS
;          This is the first user-level program to run.
; ----------------------------------------------------------------------

bits 16         ; Still operating in 16-bit Real Mode

; --- Data Section ---
prompt_msg     db "PieOS:\>", 0x00
welcome_msg    db "Welcome to PieOS. Type 'VNC' to start VNC connection.", 0x0D, 0x0A, 0x00
unknown_cmd    db "Unknown command.", 0x0D, 0x0A, 0x00
input_buffer   times 80 db 0 ; Buffer for user input (max 79 chars + null)

; --- External Subroutines (from lib.asm, vnc_protocol.asm) ---
; extern print_string, read_key, vnc_start

; ----------------------------------------------------------------------
; Subroutine: main
; Entry point for the shell application.
; ----------------------------------------------------------------------
start:
    ; Assuming the kernel has already initialized the graphics mode (800x600)
    ; and set up the interrupt vector table.

    ; Print a welcome message
    mov si, welcome_msg
    mov bx, 0x000F   ; White text (for contrast)
    call print_string

.shell_loop:
    ; 1. Display the command prompt
    mov si, prompt_msg
    mov bx, 0x0002   ; Green text
    call print_string

    ; 2. Get User Input (Requires a custom routine to read and store the line)
    call get_line_input ; (Assumes a complex routine that reads chars via 'read_key' and handles backspace)
    
    ; 3. Parse and Execute Command
    mov si, input_buffer
    
    ; Check for "VNC" command (Simple 3-character comparison)
    cmp byte [si], 'V'
    jne .check_exit
    cmp byte [si+1], 'N'
    jne .check_exit
    cmp byte [si+2], 'C'
    jne .check_exit
    
    ; If command is "VNC", start the VNC protocol
    call vnc_start      ; This function will not return until the VNC session ends
    
    jmp .shell_loop     ; Go back to the prompt after the VNC session
    
.check_exit:
    ; Check for "EXIT" or "QUIT" command
    ; (Example: cmp byte [si], 'E' ... jmp .exit_shell)

    ; If no known command was found
    mov si, unknown_cmd
    mov bx, 0x0004  ; Red text (error)
    call print_string
    
    jmp .shell_loop

; ----------------------------------------------------------------------
; Subroutine: get_line_input
; Reads characters from the keyboard into the input_buffer until Enter is pressed.
; (Implementation is complex and requires 'read_key' from lib.asm)
; ----------------------------------------------------------------------
get_line_input:
    ; Placeholder for the I/O logic
    ret

.exit_shell:
    ; Jump back to a spot in the kernel to shut down gracefully
    ; jmp kernel_shutdown_routine
    cli
    hlt
