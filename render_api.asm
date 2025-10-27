; ----------------------------------------------------------------------
; File: render_api.asm
; Purpose: Simple Graphics Primitives/API for PieOS (Mini-Mesa)
; ----------------------------------------------------------------------

bits 16

; --- External Subroutines ---
; extern draw_pixel (from graphics.asm)

; ----------------------------------------------------------------------
; Subroutine: draw_line
; Draws a line between two points using a simple algorithm (e.g., Bresenham's).
; ----------------------------------------------------------------------
; Parameters:
;   AX: Start X, BX: Start Y
;   CX: End X, DX: End Y
;   SI: Color value (e.g., 0xRRGGBB)
draw_line:
    ; (Implementation calls 'draw_pixel' iteratively)
    ret

; ----------------------------------------------------------------------
; Subroutine: fill_rect
; Draws a solid, filled rectangle.
; ----------------------------------------------------------------------
; Parameters:
;   AX: Top-Left X, BX: Top-Left Y
;   CX: Width, DX: Height
;   SI: Fill Color
fill_rect:
    ; (Implementation is a nested loop that calls 'draw_pixel' or optimized
    ;  memory writes to the framebuffer address)
    ret

; ----------------------------------------------------------------------
; Subroutine: draw_text
; Draws a string of characters at a specific coordinate.
; ----------------------------------------------------------------------
; Parameters:
;   AX: Start X, BX: Start Y
;   SI: Address of null-terminated string
;   DX: Foreground Color
draw_text:
    ; (Implementation uses a built-in or loaded font bitmap)
    ; 1. Loop through the string.
    ; 2. For each character, look up its bitmap in the font data.
    ; 3. Use 'draw_pixel' or optimized memory writes to draw the pixels of the character.
    ret
