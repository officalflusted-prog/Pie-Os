; ----------------------------------------------------------------------
; File: pipe.asm
; Purpose: Inter-Process Communication (IPC) via Pipes
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
PIPE_BUFFER_SIZE equ 4096       ; Size of the circular buffer (1 page)
MAX_PIPES equ 32                ; Maximum number of concurrent pipes

; --- Pipe Structure (24 bytes per pipe) ---
; This is stored in a dedicated kernel memory area
PIPE_STRUCT_SIZE equ 24
pipe_table times MAX_PIPES * PIPE_STRUCT_SIZE db 0 
; [0-3]: Pipe Status (Free/Used)
; [4-7]: Read Head Offset (Index into the buffer)
; [8-11]: Write Tail Offset (Index into the buffer)
; [12-15]: Read Waiter Task ID (Task ID of the process waiting to read)
; [16-19]: Write Waiter Task ID (Task ID of the process waiting to write)
; [20-23]: Buffer Physical Address (The PFA of the 4KB data buffer)

; --- External Subroutines ---
; extern vmem_alloc_physical_frame (from vmem.asm)
; extern task_manager_block_task, task_manager_unblock_task (from task_manager.asm)

; ----------------------------------------------------------------------
; Subroutine: sys_pipe_create
; Allocates kernel memory for a new pipe and returns file descriptors.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: SYS_PIPE_CREATE (from syscall.asm)
;   EBX: Pointer to two DWORDS where the read/write file descriptors will be stored
;
; Returns:
;   EAX: 0 on success, -1 on failure
; ----------------------------------------------------------------------
sys_pipe_create:
    pushad
    
    ; 1. Find a free slot in the pipe_table
    mov ecx, 0                  ; ECX = Pipe Index (ID)
.find_slot_loop:
    cmp ecx, MAX_PIPES
    je .no_free_slots           ; Failure: Max pipes reached
    
    mov esi, pipe_table         ; ESI points to start of the table
    imul esi, ecx, PIPE_STRUCT_SIZE
    add esi, pipe_table         ; ESI points to the start of the Pipe Structure
    
    cmp dword [esi], 0x00       ; Check Status (0 = Free)
    je .slot_found
    
    inc ecx
    jmp .find_slot_loop

.slot_found:
    ; 2. Allocate the 4KB physical buffer for the pipe data
    call vmem_alloc_physical_frame ; EAX = PFA of the new 4KB buffer
    
    ; 3. Initialize Pipe Structure
    mov dword [esi], 0x01       ; Set Status to Used
    mov dword [esi + 4], 0      ; Read Head = 0
    mov dword [esi + 8], 0      ; Write Tail = 0
    mov dword [esi + 12], 0     ; Read Waiter = 0
    mov dword [esi + 16], 0     ; Write Waiter = 0
    mov dword [esi + 20], eax   ; Store Buffer Physical Address (PFA)
    
    ; 4. Create and return File Descriptors (FDs)
    ; (FDs are simply the Pipe ID (ECX) mapped into the process's FD table)
    mov edx, ecx                ; EDX = Pipe ID
    ; Assuming FD 3 is read end, FD 4 is write end for the current process
    ; (This requires a routine in task_manager to manage process FDs)
    
    mov eax, 0                  ; Success
    jmp .done

.no_free_slots:
    mov eax, 0xFFFFFFFF         ; Failure: -1
    jmp .done
    
.done:
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: sys_pipe_write
; Writes data from the user buffer into the pipe's circular buffer.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: SYS_PIPE_WRITE (from syscall.asm)
;   EBX: Pipe ID (FD)
;   ECX: Address of the user's data buffer (Virtual Address)
;   EDX: Number of bytes to write
;
; Returns:
;   EAX: Number of bytes successfully written
; ----------------------------------------------------------------------
sys_pipe_write:
    pushad
    
    ; 1. Get Pipe Structure Pointer (ESI) from Pipe ID (EBX)
    ; ...
    
    ; 2. Check for Space in the Circular Buffer
    ; Calculate (Read Head - Write Tail - 1) % PIPE_BUFFER_SIZE
    ; If space is insufficient:
    ;   Set Write Waiter ID (to current task)
    ;   call task_manager_block_task (put process to sleep)
    ;   Resume when sys_pipe_read frees space.
    
    ; 3. Perform the Copy (Using the PFA in the Pipe Structure)
    ;   This involves a secure copy from the user's VIRTUAL address (ECX) 
    ;   to the pipe's PHYSICAL address (PIPE_STRUCT[20] + Write Tail).
    
    ; 4. Update Write Tail
    ; 5. Wake up the Read Waiter (if one exists)
    ;   call task_manager_unblock_task(PIPE_STRUCT[12])
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: sys_pipe_read
; Reads data from the pipe's circular buffer into the user buffer.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: SYS_PIPE_READ (from syscall.asm)
;   EBX: Pipe ID (FD)
;   ECX: Address of the user's destination buffer (Virtual Address)
;   EDX: Max number of bytes to read
;
; Returns:
;   EAX: Number of bytes successfully read
; ----------------------------------------------------------------------
sys_pipe_read:
    pushad
    
    ; 1. Get Pipe Structure Pointer (ESI)
    ; ...
    
    ; 2. Check for Data in the Circular Buffer
    ; Calculate (Write Tail - Read Head) % PIPE_BUFFER_SIZE
    ; If buffer is empty:
    ;   Set Read Waiter ID
    ;   call task_manager_block_task
    
    ; 3. Perform the Copy (from pipe PFA to user's VIRTUAL address)
    
    ; 4. Update Read Head
    ; 5. Wake up the Write Waiter (if one exists)
    ;   call task_manager_unblock_task(PIPE_STRUCT[16])
    
    popad
    ret
