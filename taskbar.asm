; ----------------------------------------------------------------------
; File: taskbar.asm
; Purpose: The persistent desktop panel for launching applications and managing tasks.
; ----------------------------------------------------------------------

bits 32

; --- Taskbar Dimensions (Hardcoded for 800x600 screen) ---
TASKBAR_HEIGHT equ 30
TASKBAR_Y_POS equ 600 - TASKBAR_HEIGHT  ; Bottom of the screen (570)
TASKBAR_COLOR equ 0x003366             ; Dark Blue/Teal

; --- Start Button Data ---
START_BUTTON_WIDTH equ 70
START_BUTTON_COLOR equ 0x0088CC        ; Light Blue

; --- External Subroutines ---
; extern fb_draw_rect_protected (from fb_manager.asm)
; extern draw_icon (from xicon.asm)
; extern draw_text_32 (from font_manager.asm)
; extern task_manager_get_list (from task_manager.asm)
; extern fl_register_window, fl_handle_event (from fl.asm)

; ----------------------------------------------------------------------
; Subroutine: taskbar_main
; The entry point for the taskbar process. Runs in an infinite loop.
; ----------------------------------------------------------------------
taskbar_main:
    pushad

    ; 1. Register the Taskbar as a permanent window (it has no frame)
    ; call fl_register_window (TASKBAR_Y_POS, 0, 800, TASKBAR_HEIGHT, .taskbar_event_handler)

    ; 2. Initial Draw
    call taskbar_redraw

.taskbar_loop:
    ; 3. Handle Events (Mouse Clicks, etc.)
    ; call fl_handle_event (for the taskbar's registered window)
    
    ; 4. Update Task List (Redraw the middle section if tasks change)
    call taskbar_update_list

    ; 5. Yield control to the scheduler
    ; call sched_yield ; Give other processes time to run
    
    jmp .taskbar_loop

; ----------------------------------------------------------------------
; Subroutine: taskbar_redraw
; Draws the entire taskbar area.
; ----------------------------------------------------------------------
taskbar_redraw:
    pushad

    ; 1. Draw the background panel (full width)
    mov eax, 0                 ; X=0
    mov ebx, TASKBAR_Y_POS     ; Y=570
    mov ecx, 800               ; Width=800
    mov edx, TASKBAR_HEIGHT    ; Height=30
    mov esi, TASKBAR_COLOR
    call fb_draw_rect_protected

    ; 2. Draw the Start Button
    mov eax, 0
    mov ebx, TASKBAR_Y_POS
    mov ecx, START_BUTTON_WIDTH
    mov edx, TASKBAR_HEIGHT
    mov esi, START_BUTTON_COLOR
    call fb_draw_rect_protected
    
    ; 3. Draw the System Clock (Right side)
    ; (Would call rtc_read_time and draw_text_32)

    ; 4. Redraw running tasks
    call taskbar_update_list
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: taskbar_update_list
; Queries the task manager and draws buttons for each running process.
; ----------------------------------------------------------------------
taskbar_update_list:
    pushad
    
    ; 1. Clear the old task area
    ; (Draw a clear rectangle over the task area)
    
    ; 2. Get the list of running processes
    ; mov edi, [task_list_buffer]
    ; call task_manager_get_list 
    
    ; 3. Loop through the list and draw a button for each process (using draw_text_32)
    
    popad
    ret
    
; ----------------------------------------------------------------------
; Subroutine: .taskbar_event_handler
; Handles user clicks on the taskbar.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Mouse X, EBX: Mouse Y, ECX: Click Type
.taskbar_event_handler:
    pushad
    
    ; Check if the click was on the Start Button (X < START_BUTTON_WIDTH)
    ; If so, display the Start Menu (a new window)
    
    ; Check if the click was on a Task Button
    ; If so, call fl_switch_focus to bring that application's window to the front
    
    popad
    ret
