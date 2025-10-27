; ----------------------------------------------------------------------
; File: start_menu.asm
; Purpose: Graphical menu for launching applications and system actions.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
MENU_WIDTH equ 200
MENU_HEIGHT equ 300
MENU_ITEM_HEIGHT equ 20
MENU_COLOR equ 0xCCCCCC               ; Light Gray Background
MENU_ITEM_TEXT_COLOR equ 0x000000     ; Black Text

; --- Menu Structure Data ---
; Array of menu items: [Label String Pointer (DD), Action Function Pointer (DD)]
menu_items:
    dd app_settings_str, app_launch_settings
    dd app_shell_str, app_launch_shell
    dd app_zip_str, app_launch_zip_util
    dd action_logout_str, action_logout
    dd action_shutdown_str, action_shutdown
menu_item_count equ ($ - menu_items) / 8

; --- Menu Item Strings ---
app_settings_str db "Settings", 0x00
app_shell_str db "Terminal (Shell)", 0x00
app_zip_str db "Zip Utility", 0x00
action_logout_str db "Log Out", 0x00
action_shutdown_str db "Shut Down", 0x00

; --- External Subroutines ---
; extern fb_draw_rect_protected (from fb_manager.asm)
; extern draw_text_32 (from font_manager.asm)
; extern fl_create_window, fl_close_window, fl_register_event (from fl.asm)
; extern shell_app_loader_launch (from shell_app_loader.asm)
; extern system_shutdown, system_logout (from kernel.asm/security.asm)

; ----------------------------------------------------------------------
; Subroutine: start_menu_launch
; Creates and displays the Start Menu window.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Mouse X coordinate (where the menu should appear)
;   EBX: Mouse Y coordinate (where the menu should appear)
start_menu_launch:
    pushad
    
    ; 1. Calculate Menu Position (just above the start button)
    mov edx, [TASKBAR_Y_POS] ; Get the taskbar Y position from taskbar.asm data
    mov ecx, edx
    sub ecx, MENU_HEIGHT     ; Top Y position
    
    ; 2. Create a new window for the menu
    ; The menu is a borderless, temporary window with high Z-order
    mov eax, 0               ; X=0 (for simplicity, aligned left)
    mov ebx, ecx             ; Y=Top Y position
    mov ecx, MENU_WIDTH
    mov edx, MENU_HEIGHT
    call fl_create_window    ; EAX returns the Window ID
    mov [start_menu_window_id], eax
    
    ; 3. Draw the menu contents
    call .draw_menu_items
    
    ; 4. Register the event handler for this menu window
    ; call fl_register_event(EAX, .menu_event_handler)
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: .draw_menu_items
; Draws the labels for all menu items within the window.
; ----------------------------------------------------------------------
.draw_menu_items:
    pushad
    
    mov esi, menu_items         ; ESI = Pointer to the item list
    mov ecx, menu_item_count    ; ECX = Number of items
    mov ebx, 0                  ; EBX = Current Y offset inside the window
    
.draw_loop:
    ; a. Draw the background of the menu item (light background)
    ; b. Draw the text label
    mov edi, [esi]              ; EDI = Pointer to the string
    mov edx, MENU_ITEM_TEXT_COLOR
    ; call draw_text_32 (draws text at X=5, Y=EBX, string=EDI)
    
    add ebx, MENU_ITEM_HEIGHT   ; Move to the next Y position
    add esi, 8                  ; Advance to the next item structure (8 bytes)
    loop .draw_loop
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: .menu_event_handler
; Handles a click on any part of the menu window.
; ----------------------------------------------------------------------
; Parameters: EAX=Mouse X, EBX=Mouse Y (relative to window), ECX=Click Type
.menu_event_handler:
    pushad
    
    ; 1. Calculate the clicked item index
    mov edx, ebx                ; EBX = Relative Y
    mov eax, MENU_ITEM_HEIGHT
    div eax                     ; EAX = Item Index clicked
    
    ; 2. Ensure index is valid
    cmp eax, menu_item_count
    jge .close_menu             ; Clicked outside the items area

    ; 3. Get the action pointer
    mov esi, menu_items
    imul esi, eax, 8            ; Offset to the clicked item structure
    add esi, 4                  ; ESI points to the Action Function Pointer
    mov edi, [esi]              ; EDI = Function Address
    
    ; 4. Close the menu immediately
    call .close_menu
    
    ; 5. Execute the action
    call edi                    ; Jump to the action function (e.g., app_launch_shell)
    
    jmp .done

.close_menu:
    mov eax, [start_menu_window_id]
    call fl_close_window
    jmp .done

; ----------------------------------------------------------------------
; Action Functions (Called directly by the handler)
; ----------------------------------------------------------------------
app_launch_settings:
    mov esi, settings_app_path
    call shell_app_loader_launch
    ret

app_launch_shell:
    mov esi, shell_app_path
    call shell_app_loader_launch
    ret

app_launch_zip_util:
    mov esi, zip_util_app_path
    call shell_app_loader_launch
    ret
    
action_logout:
    call system_logout
    ret

action_shutdown:
    call system_shutdown
    ret

.done:
    popad
    ret

; --- Data ---
start_menu_window_id dd 0
settings_app_path db "SETTINGS.EXE", 0x00
shell_app_path db "SHELL.EXE", 0x00
zip_util_app_path db "ZIPUTIL.EXE", 0x00
