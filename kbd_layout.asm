; ----------------------------------------------------------------------
; File: kbd_layout.asm
; Purpose: Manages the mapping of hardware scancodes to character codes (ASCII/Unicode).
; ----------------------------------------------------------------------

bits 32

; --- Constants for Scancode Set 1 (Common) ---
SCANCODE_LSHIFT equ 0x2A
SCANCODE_RSHIFT equ 0x36
SCANCODE_CAPSLOCK equ 0x3A
SCANCODE_ENTER equ 0x1C
SCANCODE_MAX equ 0x58      ; Maximum scancode (F12)

; --- Global State Flags ---
kbd_status_flags dd 0      ; Bitmask for Shift, Ctrl, Alt, CapsLock, NumLock states
KBD_SHIFT_BIT equ 0x0001
KBD_CAPSLOCK_BIT equ 0x0004

; --- Keyboard Layout Data Structure ---
; The layout is a simple array: [scancode] -> [unmodified char, shifted char]
; We will use separate tables for simplicity, loaded dynamically.
; NOTE: These tables would typically be loaded from a file (e.g., "/system/layouts/us.kbl")
kbd_layout_unmod times SCANCODE_MAX db 0
kbd_layout_shift times SCANCODE_MAX db 0

; --- External Subroutines ---
; extern registry_get_value (to load the default layout name)

; ----------------------------------------------------------------------
; Subroutine: kbd_layout_init
; Loads the preferred keyboard layout from the registry.
; ----------------------------------------------------------------------
kbd_layout_init:
    pushad
    
    ; 1. Load preferred layout from registry
    mov esi, registry_key_layout ; "Keyboard.Layout"
    mov edi, layout_name_buffer  ; Destination buffer for "us" or "fr"
    ; call registry_get_value
    
    ; 2. Load the corresponding layout file (e.g., "us.kbl") from ext2
    ; call ext2_read_file_to_buffer 
    ; (This fills kbd_layout_unmod and kbd_layout_shift tables)
    
    ; 3. If loading fails, fallback to the hardcoded US QWERTY layout
    call .load_default_us_qwerty
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: kbd_translate_scancode
; Translates a raw scancode into a character based on the current layout and modifier states.
; ----------------------------------------------------------------------
; Parameters:
;   AL: Raw Scancode (byte)
;
; Returns:
;   EAX: 32-bit character code (ASCII/Unicode, 0 if it's a modifier key)
;   kbd_status_flags is updated for modifier changes.
; ----------------------------------------------------------------------
kbd_translate_scancode:
    pushad
    movzx ebx, al           ; EBX = Scancode
    mov eax, 0              ; Default return value

    ; 1. Handle Modifier Keys (Shift, CapsLock)
    cmp bl, SCANCODE_LSHIFT
    je .handle_modifier
    cmp bl, SCANCODE_RSHIFT
    je .handle_modifier
    
    cmp bl, SCANCODE_CAPSLOCK
    je .handle_capslock
    
    ; 2. Determine Which Table to Use (Unmodified vs. Shifted)
    mov edx, kbd_layout_unmod ; Default to unmodified table
    
    test dword [kbd_status_flags], KBD_SHIFT_BIT
    jnz .use_shift_table      ; If SHIFT is pressed
    jmp .translate_char

.use_shift_table:
    mov edx, kbd_layout_shift
    
.translate_char:
    ; 3. Get the Character from the selected table
    cmp bl, SCANCODE_MAX
    jge .done_no_char           ; Ignore keys outside the table range

    mov al, byte [edx + ebx]    ; AL = Character code
    movzx eax, al               ; EAX = 32-bit char code

    ; 4. Apply CapsLock Logic (if applicable)
    test dword [kbd_status_flags], KBD_CAPSLOCK_BIT
    jz .check_shift_final       ; If CapsLock is OFF, skip
    
    ; Check if the resulting character is a letter (A-Z or a-z)
    ; If it is a letter, flip its case (Caps Lock only affects letters)
    
.check_shift_final:
    cmp eax, 0
    je .done_no_char            ; If no character in the table, return 0
    
    jmp .done_char

.handle_modifier:
    ; Toggle the KBD_SHIFT_BIT based on the scancode (release vs. press)
    ; Scancodes > 0x80 indicate key release
    jmp .done_no_char

.handle_capslock:
    ; Toggle the KBD_CAPSLOCK_BIT only on key *press*
    ; (Implement debouncing logic here)
    ; xor dword [kbd_status_flags], KBD_CAPSLOCK_BIT
    jmp .done_no_char

.done_char:
    popad
    ret

.done_no_char:
    mov eax, 0                  ; Return 0
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: .load_default_us_qwerty
; Hardcoded load for the US QWERTY layout (Fallback)
; ----------------------------------------------------------------------
.load_default_us_qwerty:
    ; Scancode 0x10 (Q)
    mov byte [kbd_layout_unmod + 0x10], 'q'
    mov byte [kbd_layout_shift + 0x10], 'Q'
    
    ; Scancode 0x02 (1)
    mov byte [kbd_layout_unmod + 0x02], '1'
    mov byte [kbd_layout_shift + 0x02], '!'
    
    ; ... (Populate all other scancode entries)
    ret

; --- Data ---
registry_key_layout db "Keyboard.Layout", 0x00
layout_name_buffer times 8 db 0 ; To hold "us", "fr", etc.
