; ----------------------------------------------------------------------
; File: i18n.asm
; Purpose: Core routines for Internationalization and Localization (Loading language strings).
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
I18N_LANG_DIR db "/system/lang/", 0x00 ; Directory where language files reside
MAX_STRING_ID equ 1024                 ; Maximum number of translatable strings
STRING_BUFFER_SIZE equ 256             ; Max size for a translated string

; --- Global Data ---
current_language_id db "en", 0x00      ; Default to English
language_string_table dd 0             ; Pointer to the loaded language translation table (in RAM)

; --- External Subroutines ---
; extern ext2_open, ext2_read, ext2_close (from ext2_driver.asm)
; extern vmem_alloc_pages, vmem_free_pages (for the translation table buffer)
; extern registry_get_value (to load the user's preferred language)

; ----------------------------------------------------------------------
; Subroutine: i18n_init
; Loads the preferred language translation file into memory.
; ----------------------------------------------------------------------
i18n_init:
    pushad
    
    ; 1. Get preferred language ID from the registry
    mov esi, registry_key_lang ; "System.Language"
    mov edi, current_language_id ; Destination buffer
    ; call registry_get_value
    
    ; 2. Construct the full file path (e.g., "/system/lang/fr.lang")
    call .build_language_path
    
    ; 3. Load the language file content into a memory buffer
    ; call ext2_read_file_to_buffer 
    ; mov [language_string_table], eax ; Store the buffer address
    
    ; 4. If loading fails, log a warning and fallback to English (which is the default in code)
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: i18n_get_string
; Retrieves the translated string for a given String ID.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: String ID (a 32-bit index or hash representing the desired string)
;   EDI: Destination buffer (where the translated string should be copied)
;
; Returns: EAX = Pointer to the translated string (EDI)
; ----------------------------------------------------------------------
i18n_get_string:
    pushad
    
    mov ebx, [language_string_table]
    cmp ebx, 0
    je .use_default ; If no table loaded, use hardcoded default (English)
    
    ; 1. Calculate offset in the loaded table
    ; The table structure is assumed to be an array of fixed-size strings:
    ; Offset = String ID (EAX) * STRING_BUFFER_SIZE
    imul eax, STRING_BUFFER_SIZE
    add ebx, eax            ; EBX = Address of the translated string
    
    ; 2. Copy the translated string to the destination buffer (EDI)
    mov esi, ebx
    mov ecx, STRING_BUFFER_SIZE
    rep movsb               ; Copy the string
    
    ; 3. Optional: Check for null string (if translation is missing)
    cmp byte [edi], 0x00
    je .use_default
    
    jmp .done

.use_default:
    ; If translation failed or is missing, return a hardcoded/default string
    ; (For a real OS, this would look up the default English version)
    mov esi, default_error_string
    mov edi, [esp + 4] ; Get original EDI from the stack
    call copy_string   ; Simple routine to copy string from ESI to EDI
    
.done:
    popad
    mov eax, [esp + 4] ; Return EDI (pointer to the copied string)
    ret

; ----------------------------------------------------------------------
; Subroutine: .build_language_path
; Constructs the path: "/system/lang/" + current_language_id + ".lang"
; ----------------------------------------------------------------------
.build_language_path:
    ; (String manipulation code to build the path in full_path_buffer)
    ret

; --- Data ---
registry_key_lang db "System.Language", 0x00
default_error_string db "I18N: String Missing", 0x00
full_path_buffer times 64 db 0
