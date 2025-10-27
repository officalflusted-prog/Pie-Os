; ----------------------------------------------------------------------
; File: shell_scripts.asm
; Purpose: Contains the assembly code for standard PieOS shell commands
; ----------------------------------------------------------------------

bits 16

; --- Constants and Data ---
CRLF db 0x0D, 0x0A, 0x00 ; Carriage Return, Line Feed, Null Terminator

; --- External Subroutines (from lib.asm, fat12.asm) ---
; extern print_string, load_directory (from fat12.asm)
; extern disk_buffer (a 512-byte buffer in memory)

; ----------------------------------------------------------------------
; Subroutine: echo_command
; Prints the arguments passed to it to the screen.
; ----------------------------------------------------------------------
; Parameters:
;   SI: Address of the string to be echoed (usually just after the "echo " part)
echo_command:
    pusha
    
    ; The string at SI is ready to print (e.g., "hello world\0")
    mov bx, 0x0007          ; Attribute: light gray on black
    call print_string       ; Prints the string
    
    ; Print a newline after the message
    mov si, CRLF
    call print_string
    
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: ls_command
; Lists the files and directories in the current working directory (Root for now).
; ----------------------------------------------------------------------
; Parameters:
;   None (For simplicity, always lists the root directory)
ls_command:
    pusha
    
    ; 1. Load the Root Directory into a memory buffer (using fat12.asm)
    ; Assuming the kernel or a setup routine has provided a pointer to the buffer.
    ; mov ax, [root_directory_sector_start]
    ; mov es, [disk_buffer_segment]
    ; mov bx, [disk_buffer_offset]
    ; call load_directory ; (Loads 14 root sectors into ES:BX)

    ; For demonstration, we'll assume the root directory is loaded into 'disk_buffer'
    mov di, disk_buffer     ; Start of the directory entry buffer
    mov cx, 224             ; 224 total possible entries in a 1.44MB root dir
    
.entry_loop:
    ; Check the first byte of the 32-byte directory entry at DI
    cmp byte [di], 0x00     ; 0x00: Entry is free/unused (stop scanning)
    je .done_ls             
    
    cmp byte [di], 0xE5     ; 0xE5: Entry has been deleted (skip)
    je .next_entry
    
    cmp byte [di+11], 0x0F  ; 0x0F: Long File Name (LFN) entry (skip or handle separately)
    je .next_entry
    
    ; 2. Print the 8.3 Filename
    push si                 ; Save SI (lib.asm's print_string uses it)
    mov si, di              ; SI points to the start of the 11-byte filename
    mov bx, 0x000F          ; White color
    
    ; A custom routine would be needed here to format the 8.3 name (remove spaces, add '.')
    ; For now, print the raw 11 bytes + a space.
    push cx                 ; Save entry loop counter
    mov cx, 11              ; 11 characters for the name
.print_name_loop:
    mov al, [si]
    mov ah, 0x0e            ; BIOS print char function
    int 0x10
    inc si
    loop .print_name_loop
    pop cx
    
    mov al, 0x20            ; Print a space for separation
    mov ah, 0x0e
    int 0x10

    ; 3. Check for Directory Flag and print a marker
    cmp byte [di+11], 0x10  ; 0x10 is the Directory attribute flag
    jne .not_a_dir          
    
    mov al, '/'             ; Print a '/' if it is a directory
    mov ah, 0x0e
    int 0x10
.not_a_dir:
    
    mov si, CRLF            ; Print newline
    call print_string
    pop si                  ; Restore SI
    
.next_entry:
    add di, 32              ; Move DI to the next 32-byte directory entry
    loop .entry_loop
    
.done_ls:
    popa
    ret

; ----------------------------------------------------------------------
; Data Buffer (Must be a globally accessible 512-byte segment)
disk_buffer times 512 db 0
