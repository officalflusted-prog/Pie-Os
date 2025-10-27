; --- Updated Boot Sector (Snippet for Disk Loading) ---

; ... (After printing the "Booting PieOS..." message)

; 3. Load the Kernel from the disk
; --- SET UP DISK READ PARAMETERS ---
mov ah, 0x02    ; BIOS Function 02h: Read Sector(s)
mov al, 1       ; AL: Number of sectors to read (1 sector for this small kernel)
mov ch, 0x00    ; CH: Cylinder (Track) number (0)
mov cl, 0x02    ; CL: Starting Sector number (1 is boot sector, so start at 2)
mov dh, 0x00    ; DH: Head number (0)
mov dl, [boot_drive] ; DL: Drive number (0x00 for floppy, 0x80 for hard disk)
mov bx, 0x1000  ; BX: Destination offset (We'll load the kernel at 0x1000:0000 = 0x10000)
mov es, bx      ; ES: Destination segment

; --- EXECUTE DISK READ ---
int 0x13        ; BIOS Disk Interrupt
jc .disk_error  ; If Carry Flag is set, an error occurred

; 4. Jump to the loaded kernel
jmp 0x1000:start ; Jump to the start label in the new memory segment

; --- Disk Error Handler (Optional but Recommended) ---
.disk_error:
    ; Simplified error message and hang
    mov si, error_msg
    ; ... (Print error_msg using a print loop)
    cli
    hlt

; --- New Data for Updated Boot Sector ---
boot_drive db 0x00  ; Placeholder for the boot drive number
error_msg db "Disk Error! System Halted.", 0x0d, 0x0a, 0x00
