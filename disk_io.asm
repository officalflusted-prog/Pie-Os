; ----------------------------------------------------------------------
; File: disk_io.asm
; Purpose: Native 32-bit ATA/IDE PIO Driver
; ----------------------------------------------------------------------

bits 32

ATA_DATA_PORT equ 0x1F0
ATA_SECTOR_COUNT_PORT equ 0x1F2
ATA_LBA_LOW_PORT equ 0x1F3
; ... (Other ATA port definitions)

; Subroutine: ata_read_sectors
; Reads sectors using LBA.
; Parameters: EAX=LBA address, ECX=Sector count, EDI=Destination buffer
ata_read_sectors:
    pushad
    
    ; 1. Wait for BSY=0, DRDY=1 (Drive Ready)
    call .wait_for_ready
    
    ; 2. Send LBA bytes and Sector Count
    mov dx, ATA_SECTOR_COUNT_PORT
    out dx, cl              ; Output ECX (count)
    
    ; Output LBA (28-bit LBA requires 4 separate port writes)
    ; ...
    
    ; 3. Send READ SECTORS command (0x20)
    mov al, 0x20
    mov dx, 0x1F7           ; Command Register
    out dx, al
    
    ; 4. Read Loop
    mov esi, 0              ; Read 256 words (512 bytes) per sector
.read_sector_loop:
    call .wait_for_DRQ      ; Wait for DRQ=1 (Data Request)
    
    mov dx, ATA_DATA_PORT
    mov ecx, 256            ; 256 words
    rep insw                ; Read 512 bytes into EDI
    
    ; Check if all requested sectors are read
    loop .read_sector_loop
    
    popad
    ret

; ... (Helper routines like .wait_for_ready, .wait_for_DRQ)
