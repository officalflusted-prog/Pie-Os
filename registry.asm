; ----------------------------------------------------------------------
; File: registry.asm
; Purpose: Persistent key-value store for OS and application configuration.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
REGISTRY_FILE_PATH db "/system/registry.dat", 0x00 ; Location of the file on the ext2 partition
MAX_KEYS equ 512                                   ; Max number of keys in the registry
KEY_NAME_SIZE equ 32                               ; Max size for a key name (e.g., "Taskbar.Color")
VALUE_SIZE equ 128                                 ; Max size for a value (data)
REG_ENTRY_SIZE equ KEY_NAME_SIZE + VALUE_SIZE + 4  ; Entry size (approx 164 bytes)

; --- Global Data (In-Memory Cache) ---
registry_cache times MAX_KEYS * REG_ENTRY_SIZE db 0 ; Cache for fast access
registry_cache_dirty db 0                          ; Flag: 0=Clean, 1=Needs to be written to disk

; --- External Subroutines ---
; extern ext2_open, ext2_read, ext2_write, ext2_close (from ext2_driver.asm)
; extern vmem_alloc_pages (for cache if needed)
; extern mutex_lock, mutex_unlock (for thread-safe access)

; ----------------------------------------------------------------------
; Subroutine: registry_init
; Loads the registry file from disk into the memory cache.
; ----------------------------------------------------------------------
registry_init:
    pushad
    
    ; 1. Load the registry file (REGISTRY_FILE_PATH)
    mov esi, REGISTRY_FILE_PATH
    ; call ext2_open (returns FD in EAX)
    
    ; 2. Read the entire file into the registry_cache buffer
    mov ecx, MAX_KEYS * REG_ENTRY_SIZE
    mov edi, registry_cache
    ; call ext2_read (read ECX bytes into EDI)
    
    ; 3. Close the file
    ; call ext2_close
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: registry_get_value
; Retrieves a value associated with a key from the cache.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the null-terminated Key Name string (e.g., "Display.Resolution")
;   EDI: Destination buffer for the Value (at least VALUE_SIZE bytes)
;
; Returns: EAX = Length of the value on success (0 if key not found)
; ----------------------------------------------------------------------
registry_get_value:
    pushad
    call mutex_lock ; Ensure thread-safe access to the cache
    
    mov ebx, 0                  ; EBX = Current entry index
    mov ecx, MAX_KEYS
.search_loop:
    cmp ebx, ecx
    je .key_not_found
    
    mov edx, registry_cache     ; EDX = Base of the cache
    imul edx, ebx, REG_ENTRY_SIZE
    add edx, registry_cache     ; EDX = Start of current entry
    
    ; Compare ESI (Input Key Name) with [EDX] (Key Name in cache)
    ; (Requires a custom 32-bit string comparison routine)
    call string_compare
    cmp eax, 0                  ; 0 means strings match
    je .key_found
    
    inc ebx
    jmp .search_loop

.key_found:
    ; Copy the value (starting at [EDX + KEY_NAME_SIZE + 4]) to EDI
    mov esi, edx
    add esi, KEY_NAME_SIZE + 4
    
    ; The actual value is stored after a 4-byte length field
    mov ecx, [edx + KEY_NAME_SIZE] ; ECX = Length of the stored value
    rep movsb                      ; Copy ECX bytes
    
    mov eax, ecx                   ; Return length
    call mutex_unlock
    popad
    ret

.key_not_found:
    mov eax, 0                     ; Return 0 length
    call mutex_unlock
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: registry_set_value
; Updates a key's value in the cache and marks it dirty.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the Key Name string
;   EDI: Pointer to the Value data to write
;   ECX: Length of the Value data
registry_set_value:
    pushad
    call mutex_lock
    
    ; 1. Find the key's entry (or find a free entry)
    ; ...
    
    ; 2. Write the new value and the length (ECX)
    
    ; 3. Mark the cache as dirty
    mov byte [registry_cache_dirty], 0x01
    
    call mutex_unlock
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: registry_sync
; Writes the dirty cache back to the disk file. Called on shutdown/logout.
; ----------------------------------------------------------------------
registry_sync:
    pushad
    call mutex_lock
    
    cmp byte [registry_cache_dirty], 0x00
    je .done_sync ; Nothing to write
    
    ; 1. Open the registry file for writing (truncating it)
    ; call ext2_open(REGISTRY_FILE_PATH, EXT2_O_WRITE | EXT2_O_TRUNC)
    
    ; 2. Write the entire registry_cache buffer to disk
    ; ... call ext2_write
    
    ; 3. Clear the dirty flag
    mov byte [registry_cache_dirty], 0x00
    
.done_sync:
    call mutex_unlock
    popad
    ret
