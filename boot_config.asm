; ----------------------------------------------------------------------
; File: boot_config.asm
; Purpose: Reads and manages persistent kernel configuration settings from disk.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
BOOT_CONFIG_PATH db "/boot/boot.cfg", 0x00 ; Location of the configuration file
MAX_CONFIG_ENTRIES equ 32
CONFIG_KEY_SIZE equ 32
CONFIG_VALUE_SIZE equ 64
CONFIG_ENTRY_SIZE equ CONFIG_KEY_SIZE + CONFIG_VALUE_SIZE

; --- Global Data (In-Memory Configuration Table) ---
config_table times MAX_CONFIG_ENTRIES * CONFIG_ENTRY_SIZE db 0
config_count db 0

; --- External Subroutines ---
; extern ext2_open, ext2_read, ext2_close (from ext2_driver.asm)
; extern unicode_compare_ci (for case-insensitive key lookup)
; extern string_copy (for copying values)

; ----------------------------------------------------------------------
; Subroutine: boot_config_init
; Reads the configuration file from disk and parses it into the config_table.
; ----------------------------------------------------------------------
boot_config_init:
    pushad
    
    ; 1. Load the entire BOOT_CONFIG_PATH file into a temporary buffer (using ext2_read)
    
    ; 2. Parse the buffer (assuming simple KEY=VALUE; one line per entry)
    mov esi, [temp_config_buffer_ptr]
    mov edi, config_table
    mov byte [config_count], 0
    
.parse_loop:
    ; a. Check for end-of-file/buffer
    cmp byte [esi], 0x00
    je .parsing_done
    
    ; b. Find the '=' separator
    ; c. Copy the Key (left of '=') into [EDI]
    
    ; d. Find the newline/semicolon (';' or 0x0A)
    ; e. Copy the Value (right of '=') into [EDI + CONFIG_KEY_SIZE]
    
    ; f. Increment config_count and advance EDI to the next slot
    inc byte [config_count]
    add edi, CONFIG_ENTRY_SIZE
    
    ; g. Advance ESI past the end of the current line/entry
    jmp .parse_loop

.parsing_done:
    ; (Free the temporary buffer)
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: boot_config_get_value
; Retrieves a configuration value by its key.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the null-terminated Key string (e.g., "video_mode")
;
; Returns: EAX = Pointer to the value string in the config_table (0 if key not found)
; ----------------------------------------------------------------------
boot_config_get_value:
    pushad
    
    mov ebx, 0
    movzx ecx, byte [config_count]
    
.search_loop:
    cmp ebx, ecx
    je .not_found
    
    mov edx, config_table
    imul ebx, CONFIG_ENTRY_SIZE
    add edx, ebx            ; EDX = Start of current entry
    
    ; Compare ESI (Input Key) with [EDX] (Key in table)
    mov edi, edx
    call unicode_compare_ci ; Compares strings at ESI and EDI
    cmp eax, 0              ; 0 means match
    je .found
    
    inc ebx
    jmp .search_loop

.found:
    ; Return the pointer to the value string
    mov eax, edx
    add eax, CONFIG_KEY_SIZE
    jmp .done

.not_found:
    mov eax, 0
    
.done:
    popad
    ret

; --- Data ---
temp_config_buffer_ptr dd 0 ; Pointer to the buffer holding the raw file data
