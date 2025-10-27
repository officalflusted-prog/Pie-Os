; ----------------------------------------------------------------------
; File: syscall_translator.asm
; Purpose: Intercepts and translates guest OS system calls (e.g., Linux/proot) 
;          to native π OS kernel calls.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
GUEST_LINUX_SYSCALL_INT equ 0x80    ; Standard Linux syscall interrupt
HOST_PIOS_SYSCALL_INT equ 0x81      ; Our internal dedicated syscall for host OS

; --- Global Data ---
guest_syscall_enabled dd 0          ; Flag: 1 if the current task is a guest process

; --- External Subroutines ---
; extern task_manager_is_guest (to check process type)
; extern vmem_translate_va (to map guest VA pointers to host PA)

; ----------------------------------------------------------------------
; Subroutine: syscall_handler_entry
; Primary entry point called by the main INT 0x80 handler.
; ----------------------------------------------------------------------
; Note: Assumes registers contain the guest's context (EAX=syscall num, EBX-ESI=args)
syscall_handler_entry:
    pushad

    ; 1. Check if the calling process is a guest environment
    ; call task_manager_is_guest
    ; cmp eax, 1
    ; jne .native_call_handler ; If not a guest, handle it as a normal π OS call

    ; 2. If it IS a guest, prepare for translation
    mov [guest_syscall_num], eax    ; Save the guest's EAX (syscall number)
    
    ; 3. Translate the System Call
    call syscall_translator_map

    ; 4. Execute the translated native π OS call
    ; The map routine returns the native π OS syscall number and adjusted args
    mov eax,
