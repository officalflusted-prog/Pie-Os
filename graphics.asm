; ----------------------------------------------------------------------
; File: graphics.asm
; Purpose: VESA Graphics Mode Setup and Framebuffer Management for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Constants ---
VESA_FUNC_CALL equ 0x4F    ; VESA functions are generally called with AX = 0x4Fxx
VBE_GET_INFO   equ 0x0000
VBE_SET_MODE   equ 0x0002

; --- Data Section ---
vbe_info_block times 512 db 0 ; Buffer to store VESA information block
mode_info_block times 256 db 0 ; Buffer to store VESA mode details

; Recommended VNC-friendly mode (e.g., 800x600x24-bit/32-bit color)
TARGET_MODE_WIDTH  equ 800
TARGET_MODE_HEIGHT equ 600

; Global variables to be defined in the kernel
; extern [framebuffer_addr] ; The memory address of the screen buffer

; ----------------------------------------------------------------------
; Subroutine: graphics_init
; Finds a suitable VESA graphics mode and switches the system into it.
; ----------------------------------------------------------------------
graphics_init:
    pusha
    
    ; 1. Get VBE Controller Information (Function 0x4F00)
    mov ax, VESA_FUNC_CALL | VBE_GET_INFO
    mov di, vbe_info_block  ; Load address of the buffer
    mov es, cs              ; Set segment for the buffer (assuming local segment)
    int 0x10                ; Call BIOS video interrupt
    jc .error               ; Check for error (Carry Flag set)
    cmp al, VESA_FUNC_CALL  ; Check for successful return code
    jne .error
    
    ; 2. Find a Suitable VESA Mode (e.g., 800x600 with Linear Frame Buffer)
    ; (This section would iterate through the list of available modes
    ;  found in vbe_info_block until it finds the desired resolution/depth)
    
    ; For simplicity, let's assume a known mode ID (e.g., 0x101 is common 640x480x8)
    ; In a real OS, you'd find a high-color mode (e.g., ID 0x117 for 800x600x16bpp)
    mov bx, 0x117 | 0x4000  ; Example mode ID + LFB (Linear Frame Buffer) bit
    
    ; 3. Set the VESA Mode (Function 0x4F02)
    mov ax, VESA_FUNC_CALL | VBE_SET_MODE
    int 0x10                ; Call BIOS video interrupt
    jc .error
    
    ; 4. Get Mode Information to find the Framebuffer Address
    ; (Need to call another VESA function (0x4F01) to get the LFB address
    ;  and store it in the global [framebuffer_addr] variable)

    jmp .done

.error:
    ; (Print an error message via lib.asm and halt)
    cli
    hlt

.done:
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: draw_pixel
; Sets a single pixel to a specific color (used for VNC updates).
; ----------------------------------------------------------------------
; Parameters:
;   AX: X coordinate
;   BX: Y coordinate
;   DX: Color value (e.g., 0xRRGGBB)
; ----------------------------------------------------------------------
draw_pixel:
    pusha
    
    ; 1. Calculate the offset into the framebuffer
    ; offset = (Y * pitch) + (X * bytes_per_pixel)
    ; (Uses the [framebuffer_addr] global variable)
    
    ; 2. Write the color data to that memory address
    
    popa
    ret

; --- More Subroutines: draw_rect, copy_buffer (for VNC screen updates) ---
