; ----------------------------------------------------------------------
; File: syscall.asm
; Purpose: Secure Gateway for User Applications to Access Kernel Services
;          Uses the INT 0x80 mechanism (or equivalent for 32-bit OS)
; ----------------------------------------------------------------------

bits 32

; --- System Call Numbers ---
SYS_EXIT          equ 0x01   ; Terminate current process
SYS_WRITE         equ 0x02   ; Write data to a file/console (stdout)
SYS_READ          equ 0x03   ; Read data from a file/console (stdin)
SYS_ALLOC_MEM     equ 0x04   ; Allocate memory pages
SYS_CREATE_PROC   equ 0x05   ; Create a new process

; --- External Subroutines (The actual kernel functions) ---
; extern task_manager_exit (from task_manager.asm)
; extern disk_io_write (from disk_io.asm)
; extern vmem_alloc_pages (from vmem.asm)
; extern create_process (from task_manager.asm)

; ----------------------------------------------------------------------
; Subroutine: syscall_init
; Sets up the Interrupt Descriptor Table (IDT) entry for the system call vector.
; ----------------------------------------------------------------------
syscall_init:
    ; 1. Define the system call gate descriptor (Type 0x8F or similar)
    ;    The descriptor is placed into a free slot in the IDT.
    ; 2. The gate points to the address of syscall_handler.
    
    ; Note: This is a complex IDT setup that depends on your pmode_switch.asm
    ; and is usually done once by the kernel during early boot.
    ret

; ----------------------------------------------------------------------
; Subroutine: syscall_handler
; The Interrupt Service Routine (ISR) for the system call interrupt (INT 0x80).
; ----------------------------------------------------------------------
; Convention:
;   EAX holds the System Call Number.
;   EBX, ECX, EDX, ESI, EDI hold arguments (up to 5 args).
;   The return value is placed in EAX.
; ----------------------------------------------------------------------
syscall_handler:
    ; Save all registers needed by the kernel functions
    pushad
    
    ; Ensure EAX is the only register we modify before the dispatch
    mov ebx, eax    ; Save the System Call Number (EAX) into EBX

    ; --- Dispatch Table ---
    cmp ebx, SYS_EXIT
    je .do_sys_exit
    
    cmp ebx, SYS_WRITE
    je .do_sys_write
    
    cmp ebx, SYS_READ
    je .do_sys_read
    
    cmp ebx, SYS_ALLOC_MEM
    je .do_sys_alloc_mem
    
    cmp ebx, SYS_CREATE_PROC
    je .do_sys_create_proc
    
.unknown_syscall:
    ; Handle invalid/unknown system call (e.g., set EAX to -1 and log error)
    mov eax, 0xFFFFFFFF ; Return -1 (Error)
    jmp .done

; --- Service Implementations ---
.do_sys_exit:
    ; EBX = SYS_EXIT
    ; ECX = Exit code
    mov eax, ecx ; Pass the exit code (ECX) to the kernel function
    call task_manager_exit
    ; NOTE: task_manager_exit does not return (it kills the process)

.do_sys_write:
    ; EBX = SYS_WRITE
    ; ECX = File descriptor (e.g., 1 for stdout)
    ; EDX = Buffer address
    ; ESI = Count (number of bytes to write)
    
    ; Example: Call kernel's write function
    ; call disk_io_write ; (or a wrapper for console output)
    mov eax, esi ; Assume EAX returns the number of bytes written
    jmp .done

.do_sys_read:
    ; EBX = SYS_READ
    ; ECX = File descriptor (e.g., 0 for stdin)
    ; EDX = Buffer address
    ; ESI = Max count
    
    ; call disk_io_read ; (or a wrapper for console input)
    ; mov eax, bytes_read ; Assume EAX returns the number of bytes read
    jmp .done

.do_sys_alloc_mem:
    ; EBX = SYS_ALLOC_MEM
    ; ECX = Number of pages to allocate
    ; call vmem_alloc_pages
    ; EAX returns the virtual address of the allocated block
    jmp .done

.do_sys_create_proc:
    ; EBX = SYS_CREATE_PROC
    ; ECX = Address of PE file data
    ; call create_process
    ; EAX returns the Process ID
    jmp .done

.done:
    popad ; Restore all general-purpose registers
    iret  ; Return from the interrupt (Restores CS:EIP, EFLAGS from the stack)
