; ----------------------------------------------------------------------
; File: fl_api.asm
; Purpose: User-Mode Library wrapping System Calls for Graphics, I/O, and Processes.
; ----------------------------------------------------------------------

bits 32

; --- System Call Numbers (Mirroring syscall.asm) ---
SYS_EXIT          equ 0x01
SYS_WRITE         equ 0x02
SYS_READ          equ 0x03
SYS_ALLOC_MEM     equ 0x04
SYS_CREATE_PROC   equ 0x05
SYS_FL_DRAW_RECT  equ 0x10  ; New: Graphics System Call
SYS_FL_GET_EVENT  equ 0x11  ; New: Input/Event System Call

; --- External Subroutines (Internal to this library) ---
extern _do_syscall ; The low-level wrapper that executes INT 0x80

; ----------------------------------------------------------------------
; Subroutine: fl_exit
; Terminates the current application process.
; ----------------------------------------------------------------------
; Parameters: EAX = Exit code
fl_exit:
    push ebx
    mov ebx, eax            ; Exit code to EBX (Arg 1)
    mov eax, SYS_EXIT       ; Syscall number to EAX
    call _do_syscall
    pop ebx
    ret                     ; NOTE: Should not return if kernel terminates process

; ----------------------------------------------------------------------
; Subroutine: fl_write
; Writes data to a file descriptor (e.g., stdout or a pipe).
; ----------------------------------------------------------------------
; Parameters: EAX=FD, EBX=Buffer Ptr, ECX=Count
fl_write:
    push edx
    push esi
    mov edx, ebx            ; Arg 2: Buffer Ptr
    mov esi, ecx            ; Arg 3: Count
    mov ebx, eax            ; Arg 1: FD
    mov eax, SYS_WRITE      ; Syscall number
    call _do_syscall        ; Returns bytes written in EAX
    pop esi
    pop edx
    ret

; ----------------------------------------------------------------------
; Subroutine: fl_draw_rect
; High-level function to draw a rectangle using the kernel's graphics service.
; ----------------------------------------------------------------------
; Parameters: EAX=Window ID, EBX=X, ECX=Y, EDX=W, ESI=H, EDI=Color
fl_draw_rect:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Place arguments into registers ECX, EDX, ESI, EDI for the syscall
    mov ecx, ebx            ; Arg 1: X
    mov edx, ecx            ; Arg 2: Y (Need to save/restore/re-use register)
    mov esi, edx            ; Arg 3: W
    mov edi, esi            ; Arg 4: H (Need careful register management)
    
    ; For simplicity, assuming the kernel is designed to accept 6 arguments:
    ; EAX=SYS_FL_DRAW_RECT, EBX=WID, ECX=X, EDX=Y, ESI=W, EDI=H, EBP=Color
    
    ; Re-pack registers for _do_syscall (Kernel expects 6 args)
    mov ebp, edi            ; EBP = Color (Arg 6)
    mov edi, esi            ; EDI = H (Arg 5)
    mov esi, edx            ; ESI = W (Arg 4)
    mov edx, ecx            ; EDX = Y (Arg 3)
    mov ecx, ebx            ; ECX = X (Arg 2)
    mov ebx, eax            ; EBX = Window ID (Arg 1)
    mov eax, SYS_FL_DRAW_RECT ; Syscall number
    
    call _do_syscall        ; No return value
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ----------------------------------------------------------------------
; Subroutine: fl_get_event
; Waits for and retrieves the next event (mouse, key, window resize).
; ----------------------------------------------------------------------
; Parameters: EAX=Buffer Ptr (where the event struct is stored)
fl_get_event:
    push ebx
    mov ebx, eax            ; Arg 1: Buffer Ptr
    mov eax, SYS_FL_GET_EVENT ; Syscall number
    call _do_syscall        ; Kernel writes event data directly to buffer
    pop ebx
    ret

; ----------------------------------------------------------------------
; Subroutine: _do_syscall
; Low-level assembly wrapper to trigger the system call interrupt.
; ----------------------------------------------------------------------
; Convention: EAX=Syscall number, EBX, ECX, EDX, ESI, EDI, EBP = Args 1-6
_do_syscall:
    ; Note: Registers EBX, ECX, EDX, ESI, EDI, EBP must already hold the arguments.
    int 0x80                ; Trigger the syscall handler
    ret                     ; EAX holds the return value
