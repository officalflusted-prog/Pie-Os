; ----------------------------------------------------------------------
; File: task_manager.asm
; Purpose: Preemptive Task Scheduler for PieOS (32-bit Protected Mode)
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
MAX_TASKS          equ 8      ; Maximum number of concurrent tasks
TSS_SIZE           equ 104    ; Size of a Task State Segment (TSS)
TSS_SELECTOR_BASE  equ 0x20   ; Start selector index in the GDT for TSSes (after Code/Data selectors)

; --- Global Data ---
task_count         dd 0       ; Total number of tasks currently registered
current_task_idx   dd 0       ; Index of the currently running task
task_table_base    equ 0x300000 ; Memory location for task structures (e.g., 3MB)

; --- External Subroutines ---
; extern vmem_alloc_pages (for allocating stack and memory)
; extern load_pe_file (to get initial entry point)
; extern isr_timer_handler (the entry point from the timer interrupt)

; ----------------------------------------------------------------------
; Subroutine: create_process
; Creates a new task structure, allocates memory, and registers the task.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Entry Point Address (from pe_loader.asm)
;
; Returns:
;   EAX: New Task ID (TSS selector)
; ----------------------------------------------------------------------
create_process:
    pushad
    
    ; 1. Allocate memory for the new task's stack (e.g., 8KB)
    ; call vmem_alloc_pages ; Allocates stack memory, returns Physical Base in EBP
    
    ; 2. Initialize the Task State Segment (TSS)
    mov ebx, task_table_base ; EBX = Base address of the memory for the new TSS
    add ebx, [task_count]    ; Offset to the next free TSS slot
    
    ; Clear the TSS memory
    push edi
    mov edi, ebx
    mov ecx, TSS_SIZE / 4
    xor eax, eax
    rep stosd
    pop edi
    
    ; Set the initial state for the new task in its TSS
    mov dword [ebx + 4], 0x10    ; SS (Data Selector)
    mov dword [ebx + 8], 0x10    ; CS (Code Selector)
    mov dword [ebx + 0xC], [esp_for_new_stack] ; ESP (Stack Pointer)
    mov dword [ebx + 0x10], 0x3200 ; EFLAGS (I/O Privilege Level, Interrupts Enabled)
    mov dword [ebx + 0x14], eax  ; EIP (Entry Point Address)
    
    ; 3. Register the TSS in the GDT (Requires GDT modification not shown here)
    ; The TSS must have a corresponding entry in the GDT.
    
    ; 4. Update Task Tracking
    mov eax, [task_count]
    inc dword [task_count]
    
    ; Calculate the TSS selector (e.g., 0x20, 0x28, 0x30...)
    shl eax, 3
    add eax, TSS_SELECTOR_BASE
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: isr_timer_scheduler
; The core of Preemptive Multitasking. Called by the Timer Interrupt Handler.
; ----------------------------------------------------------------------
; NOTE: This routine is called from the timer's Interrupt Stack.
isr_timer_scheduler:
    pushad
    
    ; 1. Find the next task to run
    mov eax, [current_task_idx]
    inc eax
    cmp eax, [task_count]       ; Check if index exceeds total tasks
    jge .wrap_around
    jmp .next_task

.wrap_around:
    mov eax, 0                  ; Wrap back to the first task

.next_task:
    mov [current_task_idx], eax ; Save the new index
    
    ; 2. Calculate the Selector for the new Task's TSS
    shl eax, 3                  ; Index * 8
    add eax, TSS_SELECTOR_BASE  ; Add base selector value
    
    ; 3. Perform the Context Switch via a Far Jump
    ; JMP FAR is the most efficient way to switch contexts using TSS.
    
    ; Load the Task Register (TR) to point to the current task's TSS
    movzx ebx, word [current_TR_selector] ; Load the current task's TSS selector
    ltr bx                              ; LTR saves the CPU state to the *old* TSS
    
    ; Jump to the new TSS selector (EAX)
    jmp eax                             ; The jump command loads the new TSS 
                                        ; and restores the saved state of the new task.
    
    ; This part is unreachable as the jump transfers control to a new stack/task.
    popad
    iret ; (If not using TSS jump, we'd manually pop registers and IRET)
