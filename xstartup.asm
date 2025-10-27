; ----------------------------------------------------------------------
; File: xstartup.asm
; Purpose: Initializes the VNC server, handles login, and starts the desktop.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
LOGIN_WINDOW_ID equ 0x01
VNC_WELCOME_MSG db "Welcome to PieOS. Login required for VNC session.", 0x0A, 0x00
LOGIN_PROMPT db "Username: ", 0x00
PASS_PROMPT db "Password: ", 0x00

; --- External Subroutines ---
; extern fb_draw_rect_protected (from fb_manager.asm)
; extern draw_text_32 (from font_manager.asm)
; extern fl_create_window, fl_redraw_desktop, fl_handle_event (from fl.asm)
; extern check_password (from security.asm)
; extern login_user (from security.asm)
; extern vnc_start (from vnc_protocol.asm - starts the server side listener)
; extern settings_main (The first application to run after login)

; ----------------------------------------------------------------------
; Subroutine: xstartup_main
; The initial application called by the kernel's desktop_manager.
; ----------------------------------------------------------------------
xstartup_main:
    pushad
    
    ; 1. Initialize VNC Server Listener
    ; The PieOS VNC server is passive—it waits for a client connection.
    call vnc_server_init 

    ; 2. Draw the Login Screen
    call .draw_login_screen
    
    ; 3. Enter the Login Loop
.login_loop:
    ; a. Wait for and handle keyboard/mouse input (fl_handle_event)
    ; b. When user presses ENTER, process the credentials
    
    ; (For simplicity, we bypass user input and use a hardcoded check)
    call .get_credentials_stub ; Placeholder for getting input
    
    ; c. Check credentials
    mov esi, user_input_buffer ; ESI points to the password
    call check_password        ; Checks against security.asm hash
    
    cmp eax, 1                 ; AX=1 means success
    je .login_success
    
    ; Display Error Message (and redraw prompt)
    jmp .login_loop

.login_success:
    ; 4. Set the system state to 'Authenticated'
    mov esi, username_buffer ; Pass the username (e.g., "piuser")
    call login_user          ; Sets the is_authenticated flag in security.asm

    ; 5. Start the Desktop Environment
    mov esi, "Login Successful. Starting Desktop...", 0x0A, 0x00
    call draw_text_32
    
    ; Launch the main Desktop/Settings Application
    call settings_main 
    
    jmp .done

; ----------------------------------------------------------------------
; Subroutine: .draw_login_screen
; Sets up the graphical login prompt.
; ----------------------------------------------------------------------
.draw_login_screen:
    ; 1. Draw a dark background (using fb_draw_rect_protected)
    ; 2. call fl_create_window to create a central login box (LOGIN_WINDOW_ID)
    ; 3. Draw the VNC_WELCOME_MSG and prompts (using draw_text_32)
    ret

; ----------------------------------------------------------------------
; Subroutine: vnc_server_init
; Placeholder to start the VNC server process.
; ----------------------------------------------------------------------
vnc_server_init:
    ; 1. call socket_create_listen (from tcpip.asm) on port 5900.
    ; 2. call create_process to run the VNC server handler process.
    ret

.get_credentials_stub:
    ; This would read from the input_manager_32.asm buffers
    mov dword [user_input_buffer], 'pieo' ; Hardcoded password "pieos"
    mov byte [user_input_buffer + 4], 's'
    mov byte [user_input_buffer + 5], 0x00
    ret

.done:
    popad
    ret

; --- Data ---
username_buffer db "piuser", 0x00
user_input_buffer times 16 db 0
