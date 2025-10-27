; ----------------------------------------------------------------------
; File: timer_sched.asm
; Purpose: System Timekeeping and Cooperative Task Scheduler for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Constants for PIT (Programmable Interval Timer) ---
PIT_COUNTER_PORT equ 0x40  ; Data port for Counter 0
PIT_COMMAND_PORT equ 0x43  ; Command Register
PIT_FREQ_DIVISOR equ 11932 ; For approx. 100 Hz (10ms tick)

; --- Global Data ---
system_ticks dw 0          ; Counts timer ticks since boot (used for system time)
task_table times 8 * 4 db 0 ; Simple table: 8 tasks, 4 bytes per entry (CS:IP)
current_task_index db 0    ; Index of the currently running task

; --- External Subroutines ---
; extern timer_isr (from interrupts.asm)
; extern print_string (from lib.asm)

; ----------------------------------------------------------------------
; Subroutine: timer_init
; Initializes the PIT hardware to generate timer interrupts (IRQ 0).
; ----------------------------------------------------------------------
timer_init:
    pusha
    
    ; 1. Command Word (Counter 0, LSB then MSB, Rate Generator Mode 2, Binary)
    mov al, 0x34
    out PIT_COMMAND_PORT, al
    
    ; 2. Set the Divisor (Example: 11932 for 100Hz)
    mov ax, PIT_FREQ_DIVISOR
    out PIT_COUNTER_PORT, al  ; Write LSB
    mov al, ah
    out PIT_COUNTER_PORT, al  ; Write MSB
    
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: isr_timer_handler (Called every time the timer fires - from interrupts.asm)
; Updates the system time and calls the scheduler.
; ----------------------------------------------------------------------
isr_timer_handler:
    pusha
    
    ; 1. Increment System Tick Counter
    inc word [system_ticks]
    
    ; 2. Call the Scheduler (only if a Task Yield hasn't already happened)
    ; This is where an OS would call a high-priority task switch.
    ; For simplicity, we just return from interrupt for now.

    ; 3. Send EOI (End of Interrupt) to the PIC (Required for IRQ 0)
    mov al, 0x20
    out 0x20, al
    
    popa
    iret ; Return from interrupt

; ----------------------------------------------------------------------
; Subroutine: sched_register_task
; Adds a new task (program) to the scheduler's task table.
; ----------------------------------------------------------------------
; Parameters:
;   CX: Program Segment (CS)
;   DX: Program Offset (IP)
sched_register_task:
    pusha
    
    mov al, [current_task_index]
    shl ax, 2                 ; Multiply index by 4 (4 bytes per entry)
    mov si, ax                ; SI is offset into task_table
    
    mov [task_table+si], cx   ; Store CS
    mov [task_table+si+2], dx ; Store IP
    
    inc byte [current_task_index] ; Increment task count
    
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: sched_yield
; The running task voluntarily gives up control to the next task.
; ----------------------------------------------------------------------
sched_yield:
    pusha
    
    ; 1. Save the state of the current task (CS:IP is handled implicitly by RETF)
    ;    (Need to save all registers (AX, BX, CX, DX, SI, DI, SP, BP) onto the stack!)
    
    ; 2. Move to the next task in the table
    mov al, [current_task_index]
    inc al
    and al, 0x07              ; Wrap around if necessary (0 to 7)
    mov [current_task_index], al
    
    ; 3. Load the new task's state
    mov ah, 0x00
    shl ax, 2
    mov si, ax                ; SI is offset into task_table
    
    mov cx, [task_table+si]   ; CX = New CS
    mov dx, [task_table+si+2] ; DX = New IP
    
    ; 4. Restore the new task's saved registers from its stack!
    
    popa                      ; Restore scheduler's registers
    
    ; Jump to the new task (using a far jump)
    jmp far [task_table+si]   ; This is a very simplified jump
