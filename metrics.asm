; ----------------------------------------------------------------------
; File: metrics.asm
; Purpose: Centralized storage for real-time system metrics and performance data.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
LOG_BUFFER_SIZE equ 4096 * 2    ; 8KB log buffer

; --- Global Data (System State & Performance) ---
sys_metrics:
    ; CPU/Task Metrics (Updated by task_manager.asm/timer_sched.asm)
    cpu_usage_percent dw 0      ; Current CPU load percentage
    total_cpu_cycles_spent dd 0 ; Total cycles spent in user code
    total_idle_cycles dd 0      ; Total cycles spent in idle task
    
    ; Memory Metrics (Updated by vmem.asm/pager.asm)
    total_physical_frames dd 0  ; Total RAM frames
    free_physical_frames dd 0   ; Available RAM frames
    total_swap_pages dd 0       ; Total pages in swap partition
    used_swap_pages dd 0        ; Used swap pages
    
    ; System Uptime & Status (Updated by rtc.asm/kernel.asm)
    system_boot_timestamp dd 0  ; RTC time when the kernel was loaded
    system_uptime_seconds dd 0  ; Total seconds since boot
    authenticated_user_id dd 0  ; Current logged-in user ID
    
    ; I/O Metrics (Updated by disk_io.asm/ahci_driver.asm)
    disk_read_count dd 0        ; Total sectors read since boot
    disk_write_count dd 0       ; Total sectors written since boot

; --- Logging Buffer ---
system_log_buffer times LOG_BUFFER_SIZE db 0
log_buffer_head dd 0                ; Next write position in the circular buffer

; --- External Subroutines ---
; extern rtc_read_time (for timestamping)

; ----------------------------------------------------------------------
; Subroutine: metrics_update_uptime
; Called regularly by the timer interrupt to update the system clock.
; ----------------------------------------------------------------------
metrics_update_uptime:
    pushad
    inc dword [system_uptime_seconds]
    ; (Code to calculate CPU usage based on idle cycles vs. total cycles)
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: metrics_log_event
; Writes a formatted string event to the circular system log buffer.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Event Severity (DEBUG, INFO, ERROR)
;   ESI: Pointer to the null-terminated message string
metrics_log_event:
    pushad
    
    ; 1. Get current time (rtc_read_time) and format the timestamp.
    
    ; 2. Format the log line: [TIME] [SEV] [MESSAGE] \n
    
    ; 3. Write to the circular buffer (system_log_buffer) at [log_buffer_head]
    ; (Must handle wrapping around the buffer size)
    
    ; 4. Advance log_buffer_head
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: syscall_get_metrics
; System call handler to copy the metrics structure to a user-provided buffer.
; ----------------------------------------------------------------------
; Parameters: EAX=Buffer Pointer, EBX=Buffer Size
syscall_get_metrics:
    ; Ensures user-mode applications can read system status securely.
    ; Copies the sys_metrics structure to EAX.
    ret
