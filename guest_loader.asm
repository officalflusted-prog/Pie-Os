; ----------------------------------------------------------------------
; File: guest_loader.asm
; Purpose: User-mode application to initialize the Guest (proot-like) environment.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
GUEST_INIT_PATH db "/GUEST/INIT.BIN", 0x00 ; The guest OS's initial binary
SYS_EXECVE_GUEST equ 0x07                  ; A new syscall number for guest execution
TASK_FLAG_GUEST equ 0x0001                 ; Flag to set on the new process

; --- External Subroutines ---
; extern fl_exit (from fl_api.asm)
; extern fl_write (for printing status messages)

; ----------------------------------------------------------------------
; Subroutine: main
; Entry point for the 'Linux-Term' application.
; ----------------------------------------------------------------------
main:
    pushad
    
    ; 1. Print Status Message
    mov eax, 1                      ; FD=stdout
    mov ebx, msg_loading
    mov ecx, msg_loading_len
    call fl_write
    
    ; 2. Attempt to Execute the Guest Initializer
    
    ; Setup arguments for the new SYS_EXECVE_GUEST syscall:
    mov eax, SYS_EXECVE_GUEST       ; Syscall number
    mov ebx, GUEST_INIT_PATH        ; Arg 1: Path to the guest's initial binary
    mov ecx, 0                      ; Arg 2: Argv (none for now)
    mov edx, 0                      ; Arg 3: Env (none for now)
    mov esi, TASK_FLAG_GUEST        ; Arg 4: Special flag to enable translation

    ; Execute the syscall. This will create a new process and replace 
    ; the current task's memory space with the guest binary.
    int 0x80                        
    
    ; NOTE: If successful, the code below this point is never executed
    ; because the process context is replaced by GUEST/INIT.BIN.

    ; 3. If Syscall Fails (Error Path)
    mov eax, 1
    mov ebx, msg_error
    mov ecx, msg_error_len
    call fl_write
    
    ; 4. Exit
    mov eax, 1                      ; Exit code 1
    call fl_exit                    ; Use the fl_api wrapper
    
    popad
    ret

; --- Data ---
msg_loading db "GUEST: Starting guest environment...", 0x0A, 0x00
msg_loading_len equ $ - msg_loading
msg_error db "GUEST: Failed to load guest environment.", 0x0A, 0x00
msg_error_len equ $ - msg_error
