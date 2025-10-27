; ----------------------------------------------------------------------
; File: fat12.asm
; Purpose: FAT12 File System Driver for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Data Section: Constants and Variables ---
SECTOR_SIZE equ 512
ROOT_DIR_ENTRIES equ 224 ; Common for a 1.44MB floppy
FAT_SECTORS equ 9        ; Number of sectors per FAT copy
RESERVED_SECTORS equ 1   ; Usually just the Boot Sector

; Global variables to be defined in the kernel or accessible here
; extern [boot_drive]
; extern [disk_buffer] ; A 512-byte buffer in RAM for reading sectors

; ----------------------------------------------------------------------
; Subroutine: read_sectors
; A low-level disk read function (similar to the one in boot.asm, but
; more robust for reading multiple sectors).
; ----------------------------------------------------------------------
; Parameters:
;   AL: number of sectors to read
;   CH: cylinder/track
;   CL: starting sector (1-63)
;   DH: head
;   ES:BX: memory address to load data to
;   DL: boot drive number
; ...
read_sectors:
    ; (Implementation would involve calling int 13h, error checking, and retrying)
    ; (For simplicity, assume this relies on the lib.asm's disk I/O routines)
    ret

; ----------------------------------------------------------------------
; Subroutine: load_file
; Locates and loads a file into memory using the FAT12 structure.
; ----------------------------------------------------------------------
; Parameters:
;   SI: Address of the filename (e.g., "SHELL   BIN")
;   ES:BX: Destination memory address for the file data
;
; Returns:
;   CX: Size of the loaded file in bytes
;   Carry Flag set on error
; ----------------------------------------------------------------------
load_file:
    pusha
    
    ; 1. Calculate the starting sector of the Root Directory
    ; Root Directory starts after the Reserved Sectors and the two FAT copies
    mov ax, RESERVED_SECTORS
    mov bl, 2
    mul bl                  ; AX = RESERVED_SECTORS * 2 FAT copies
    add ax, RESERVED_SECTORS ; Add the boot sector itself
    mov [root_sector], ax   ; Store the starting sector number

    ; 2. Loop through Root Directory sectors
    mov cx, ROOT_DIR_ENTRIES / 16 ; Number of sectors in the root dir (224/16 = 14)
    mov bx, 0                   ; Current sector count for the root dir
    
.read_root_loop:
    ; Calculate physical sector number
    mov ax, [root_sector]
    add ax, bx
    
    ; Load one root directory sector into [disk_buffer]
    ; call read_sectors ; (Simplified: assume we read the sector here)
    
    ; 3. Search the directory entries in the buffer
    mov di, 0x0000          ; Start DI at the beginning of the 512-byte buffer
.search_entry_loop:
    ; Compare the 8.3 filename in [SI] with the 11-byte name in the directory entry at [disk_buffer + DI]
    ; If match is found:
    ;   a. Read the starting cluster number from the directory entry.
    ;   b. Follow the FAT chain to read all data clusters/sectors into ES:BX.
    ;   c. Exit and return success.
    
    ; If no match: increment DI by 32 (size of one directory entry)
    ; If DI reaches 512, continue to .read_root_loop
    
    jmp .exit_failure       ; If loop finishes without finding file

    inc bx                  ; Next root directory sector
    loop .read_root_loop    ; Decrement CX and loop

.exit_failure:
    stc                     ; Set Carry Flag for error
    popa
    ret

; ... (Other necessary helper functions like 'get_fat_entry')
