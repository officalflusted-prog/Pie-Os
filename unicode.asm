; ----------------------------------------------------------------------
; File: unicode.asm
; Purpose: Core routines for Unicode Code Points and UTF-8 encoding/decoding.
; ----------------------------------------------------------------------

bits 32

; --- Constants for UTF-8 Detection ---
UTF8_MASK_1BYTE equ 0x80    ; 1-byte char starts with 0xxxxxxx
UTF8_MASK_2BYTE equ 0xC0    ; 2-byte char starts with 110xxxxx
UTF8_MASK_3BYTE equ 0xE0    ; 3-byte char starts with 1110xxxx
UTF8_MASK_4BYTE equ 0xF0    ; 4-byte char starts with 11110xxx
UTF8_CONT_BYTE_MASK equ 0xC0 ; Continuation bytes start with 10xxxxxx

; --- External Subroutines ---
; (None needed here, as these are foundational routines)

; ----------------------------------------------------------------------
; Subroutine: unicode_decode_utf8
; Decodes the next character from a UTF-8 stream.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the UTF-8 encoded string buffer
;
; Returns:
;   EAX: 32-bit Unicode Code Point
;   ESI: Advanced to the start of the next UTF-8 character
; ----------------------------------------------------------------------
unicode_decode_utf8:
    push ebx
    push ecx
    push edx
    
    movzx ebx, byte [esi]   ; EBX = First byte of the character
    mov eax, ebx            ; EAX = Result (Code Point)
    inc esi                 ; Default: advance by 1 byte
    
    ; 1. Check for 1-byte character (ASCII)
    test bl, UTF8_MASK_1BYTE
    jz .done_decoding       ; If 0xxxxxxx, it's a 1-byte char
    
    ; 2. Check for 2-byte character
    test bl, UTF8_MASK_2BYTE
    cmp bl, UTF8_MASK_3BYTE ; Checks for 110xxxxx (0xC0 to 0xDF)
    jl .decode_2_byte
    
    ; 3. Check for 3-byte character
    test bl, UTF8_MASK_3BYTE
    cmp bl, UTF8_MASK_4BYTE ; Checks for 1110xxxx (0xE0 to 0xEF)
    jl .decode_3_byte
    
    ; 4. Check for 4-byte character
    test bl, UTF8_MASK_4BYTE
    cmp bl, 0xF8            ; Checks for 11110xxx (0xF0 to 0xF7)
    jl .decode_4_byte
    
    ; 5. Error or Continuation Byte (Treat as error or skip)
    jmp .done_decoding      ; Return the single byte

; --- Decoding Logic ---
.decode_4_byte:
    ; First byte: 11110xxx (Extract 3 bits)
    and al, 0x07            ; Mask off the leading 11110
    mov ecx, 3
    shl eax, 18             ; Prepare 3 bits for high position (3+6+6+6 = 21 bits total)
    
    ; Continuation bytes (3 more)
    call .get_cont_byte     ; Get next byte, EAX |= (byte & 0x3F) << 12
    call .get_cont_byte     ; EAX |= (byte & 0x3F) << 6
    call .get_cont_byte     ; EAX |= (byte & 0x3F) << 0
    inc esi
    inc esi
    inc esi
    jmp .done_decoding

.decode_3_byte:
    ; First byte: 1110xxxx (Extract 4 bits)
    and al, 0x0F
    mov ecx, 2
    shl eax, 12             ; Prepare 4 bits for middle position
    
    ; Continuation bytes (2 more)
    call .get_cont_byte     ; EAX |= (byte & 0x3F) << 6
    call .get_cont_byte     ; EAX |= (byte & 0x3F) << 0
    inc esi
    inc esi
    jmp .done_decoding

.decode_2_byte:
    ; First byte: 110xxxxx (Extract 5 bits)
    and al, 0x1F
    mov ecx, 1
    shl eax, 6              ; Prepare 5 bits for low position
    
    ; Continuation byte (1 more)
    call .get_cont_byte     ; EAX |= (byte & 0x3F) << 0
    inc esi
    jmp .done_decoding

; Helper: Reads the next byte as a continuation byte and incorporates it into EAX
; ECX is the number of remaining continuation bytes
.get_cont_byte:
    push edx
    movzx edx, byte [esi + ecx] ; Get the next continuation byte
    inc ecx
    
    ; Check if it's a valid continuation byte (10xxxxxx)
    test dl, UTF8_CONT_BYTE_MASK
    cmp dl, UTF8_MASK_2BYTE
    jge .invalid_cont_byte  ; If it's not 10xxxxxx, it's an error
    
    and dl, 0x3F            ; Mask off the leading 10 (keep 6 bits)
    
    mov ebx, ecx
    shl ebx, 3              ; Shift factor for the 6 bits
    sub ebx, 6              ; Adjust shift factor (24, 18, 12, 6, 0)
    
    shl edx, cl             ; Shift the 6 bits into place (simplified placeholder)
    or eax, edx             ; Merge into the final code point
    
    pop edx
    ret

.invalid_cont_byte:
    mov eax, 0xFFFD         ; Return Unicode REPLACEMENT CHARACTER on error
    pop edx
    ret

.done_decoding:
    pop edx
    pop ecx
    pop ebx
    ret

; ----------------------------------------------------------------------
; Subroutine: unicode_encode_utf8
; Encodes a 32-bit Unicode Code Point into a UTF-8 stream.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: 32-bit Unicode Code Point
;   EDI: Destination buffer pointer
;
; Returns:
;   EAX: Number of bytes written (1 to 4)
;   EDI: Advanced to the end of the written character
; ----------------------------------------------------------------------
unicode_encode_utf8:
    ; (Reverse logic of decoding, writing 1 to 4 bytes based on the code point's value)
    ret
