; ----------------------------------------------------------------------
; File: security.asm
; Purpose: User Authentication and Session Management for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Constants and Data ---

MAX_PASS_LEN equ 16       ; Maximum length for a password
USER_TABLE_SIZE equ 32    ; Size of one user entry (e.g., Username, Hashed Pass)

; --- Stored User Data ---
; NOTE: In a real OS, this would be loaded from a file, but here we hardcode
; a simple user for demonstration.
; User: "piuser" (6 bytes)
; Password: "pieos" (5 bytes)
; The simple hash is just a XOR key.

user_piuser      db "piuser", 0x00, 0x00 ; 8-byte username (padded with 0)
password_hash    db 0x6A, 0x6E, 0x6E, 0x6C, 0x72, 0x00, 0x00, 0x00 ; Hashed "pieos" (XOR 0x05)

current_user     db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Currently logged-in user (8 bytes)
is_authenticated db 0x00  ; Flag: 0x00 = Logged out, 0x01 = Logged in

; ----------------------------------------------------------------------
; Subroutine: check_password
; Compares a given plaintext password against the stored hash.
; ----------------------------------------------------------------------
; Parameters:
;   SI: Address of the null-terminated plaintext password input (from input buffer)
;
; Returns:
;   AX: 1 if successful, 0 if failure
; ----------------------------------------------------------------------
check_password:
    pusha
    
    mov cx, MAX_PASS_LEN      ; Use CX as the loop counter
    mov di, password_hash     ; Destination pointer to the stored hash
    mov bl, 0x05              ; Simple XOR key (for this example)
    mov ax, 1                 ; Assume success

.compare_loop:
    mov al, [si]              ; Load input character
    cmp al, 0x00              ; Check for null terminator
    je .password_end          ; If done, check if the stored hash is also done
    
    xor al, bl                ; Apply the simple XOR hash to the input char
    cmp al, [di]              ; Compare with the stored hashed char
    jne .auth_failed          ; If they don't match, authentication fails

    inc si                    ; Next input character
    inc di                    ; Next hash byte
    loop .compare_loop        ; Decrement CX and loop
    
.password_end:
    ; Check if the stored hash also ended (meaning lengths matched)
    cmp byte [di], 0x00
    jne .auth_failed          ; If hash is longer, failure
    
    jmp .auth_success

.auth_failed:
    mov ax, 0                 ; Set return value to 0 (Failure)
    jmp .done

.auth_success:
    ; AX is already 1 (Success)
    
.done:
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: login_user
; Completes the login process by setting the global state.
; ----------------------------------------------------------------------
; Parameters:
;   SI: Address of the username (e.g., user_piuser)
login_user:
    pusha
    
    ; 1. Copy the username to the global state
    mov cx, 8                 ; 8 bytes for username
    mov di, current_user      ; Destination
    cld                       ; Clear Direction Flag (for forward copy)
    rep movsb                 ; Copy 8 bytes from SI to DI
    
    ; 2. Set the authenticated flag
    mov byte [is_authenticated], 0x01

    popa
    ret
    
; ----------------------------------------------------------------------
; Subroutine: vnc_auth_handler
; Integrates VNC's security handshake with the OS login.
; ----------------------------------------------------------------------
; NOTE: This is a high-level conceptual stub. VNC authentication is complex.
vnc_auth_handler:
    pusha
    
    cmp byte [is_authenticated], 0x01
    je .vnc_auth_success      ; If already logged in, skip VNC password
    
    ; 1. VNC Server sends a SecurityType message (e.g., VNC Authentication)
    ; 2. VNC Server sends a challenge (e.g., 16-byte random data)
    ; 3. VNC Client encrypts the challenge with the user's password (DES/AES required!)
    ;    (This requires a complex crypto library that is not in 16-bit core)
    
    ; For simple PieOS, we'll just require a successful login first.
    mov ax, 0                 ; Assume failure if not logged in
    jmp .done_vnc
    
.vnc_auth_success:
    mov ax, 1                 ; Success (VNC can continue)

.done_vnc:
    popa
    ret
