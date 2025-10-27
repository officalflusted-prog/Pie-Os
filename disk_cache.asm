; ----------------------------------------------------------------------
; File: disk_cache.asm
; Purpose: Sector Caching for PieOS (Focusing on FAT and Root Directory)
; ----------------------------------------------------------------------

bits 16

; --- Constants ---
CACHE_SLOTS equ 4           ; Number of sectors to cache (e.g., FAT sectors, Root Dir sectors)
SECTOR_SIZE equ 512

; --- Cache Data Structure (4 slots * 516 bytes per slot) ---
; Each slot stores: 
;   [0-1]: Sector Number (DW)
;   [2]: Dirty Flag (DB) - 0x00=Clean, 0x01=Dirty (needs write-back)
;   [3]: Reserved/Usage Counter (DB)
;   [4-515]: 512 bytes of Sector Data
CACHE_ENTRY_SIZE equ 516
CACHE_TOTAL_SIZE equ CACHE_SLOTS * CACHE_ENTRY_SIZE

; The cache data structure itself
disk_cache times CACHE_TOTAL_SIZE db 0

; ----------------------------------------------------------------------
; Subroutine: cache_read
; Attempts to read a sector from the cache. If not found, reads from disk and caches it.
; ----------------------------------------------------------------------
; Parameters:
;   AX: Sector Number to read (Logical Sector Number - LSN)
;   ES:BX: Destination memory address for the 512 bytes of data
;
; Returns:
;   Carry Flag clear (CF=0) on success, Carry Flag set (CF=1) on unrecoverable disk error.
; ----------------------------------------------------------------------
cache_read:
    pusha
    
    ; 1. Search the Cache
    mov cx, CACHE_SLOTS         ; Loop CACHE_SLOTS times
    mov si, disk_cache          ; SI points to the start of the cache
.search_loop:
    cmp ax, [si]                ; Compare requested AX (LSN) with stored LSN at [si]
    je .hit                     ; Cache Hit!
    add si, CACHE_ENTRY_SIZE    ; Move to the next cache slot
    loop .search_loop           ; Decrement CX and loop
    
.miss:
    ; 2. Cache Miss: Find a Free/Victim Slot
    ; (For simplicity, we'll use the first slot after checking its 'Dirty' status)
    
    mov si, disk_cache          ; Reset SI to the start
    
    ; Check if the slot is Dirty (needs to be written back before being overwritten)
    cmp byte [si+2], 0x01       ; Dirty Flag
    jne .overwrite_slot         ; If clean, proceed
    
    ; If Dirty, write it back to disk before use (Cache Write-Back Policy)
    push ax                     ; Save requested LSN
    mov ax, [si]                ; Load LSN of the dirty sector
    call .write_slot_to_disk    ; Write the sector to disk
    pop ax                      ; Restore requested LSN
    
.overwrite_slot:
    ; 3. Read Sector from Physical Disk
    ; We assume a global disk read routine exists (e.g., from fat12.asm)
    push es                     ; Save destination segment ES:BX
    push bx
    
    mov bx, si                  ; BX points to the new cache slot
    add bx, 4                   ; BX now points to the 512-byte data buffer within the slot
    ; call read_sectors_low_level (AX=LSN, ES:BX=destination)
    
    pop bx
    pop es
    
    jc .disk_error              ; Check for disk read failure
    
    ; 4. Update Cache Slot Metadata
    mov [si], ax                ; Store the LSN
    mov byte [si+2], 0x00       ; Set Dirty Flag to Clean
    
    ; 5. Copy the newly loaded data to the final destination (ES:BX)
    mov cx, 256                 ; Copy 512 bytes (256 words)
    mov si, si                  ; Source is the start of the data in cache slot
    add si, 4
    rep movsw                   ; Copy from [DS:SI] to [ES:DI] (Requires segment setup)
    
    clc                         ; Clear Carry Flag (Success)
    jmp .done

.hit:
    ; Cache Hit! Copy data from cache slot to destination (ES:BX)
    mov cx, 256                 ; 256 words = 512 bytes
    mov si, si                  ; Source is the start of the data in cache slot
    add si, 4
    rep movsw                   ; Copy from [DS:SI] to [ES:DI] (Requires segment setup)
    
    clc                         ; Clear Carry Flag (Success)
    jmp .done

.disk_error:
    stc                         ; Set Carry Flag (Disk Error)
    
.done:
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: cache_write
; Writes data to the cache. If not in cache, reads, modifies, and marks as dirty.
; ----------------------------------------------------------------------
; Parameters:
;   AX: Sector Number (LSN)
;   ES:BX: Source memory address of the 512 bytes of data to write
; ----------------------------------------------------------------------
cache_write:
    pusha
    
    ; 1. Search the Cache (Same as cache_read)
    ; ... (Find or create a cache slot for AX)
    
    ; 2. Copy the source data (ES:BX) into the cache slot's data buffer
    ; ... (Copy 512 bytes from ES:BX to the cache slot)
    
    ; 3. Mark the slot as Dirty
    ; mov byte [si+2], 0x01
    
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: sync_disk
; Writes all 'Dirty' sectors in the cache back to the physical disk.
; ----------------------------------------------------------------------
sync_disk:
    pusha
    
    mov cx, CACHE_SLOTS         ; Loop CACHE_SLOTS times
    mov si, disk_cache          ; SI points to the start of the cache
.sync_loop:
    cmp byte [si+2], 0x01       ; Check Dirty Flag
    jne .next_slot              ; If clean, skip
    
    ; If Dirty, write it back
    push cx
    push si
    mov ax, [si]                ; AX = LSN
    call .write_slot_to_disk    ; Write the sector to disk
    mov byte [si+2], 0x00       ; Mark as Clean
    pop si
    pop cx
    
.next_slot:
    add si, CACHE_ENTRY_SIZE    ; Move to the next cache slot
    loop .sync_loop             ; Decrement CX and loop
    
    popa
    ret

; ----------------------------------------------------------------------
; Helper: .write_slot_to_disk
; Writes the 512 bytes of data at [SI+4] to the disk sector in AX.
; ----------------------------------------------------------------------
; Parameters:
;   AX: LSN
;   SI: Pointer to the cache slot start (disk_cache + index*516)
.write_slot_to_disk:
    ; (Implementation would involve setting up disk write parameters and calling int 13h)
    ; (Requires complex low-level disk I/O routines)
    ret
