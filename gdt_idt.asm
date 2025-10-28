; gdt_idt.asm - Minimal GDT and IDT setup for Pi-OS
[bits 32]

section .data
gdt_start:
    dd 0x00000000      ; Null descriptor
    dd 0x00000000
gdt_code:
    dd 0x0000FFFF      ; Code segment
    dd 0x00CF9A00
gdt_data:
    dd 0x0000FFFF      ; Data segment
    dd 0x00CF9200
gdt_end:

section .bss

section .text
global init_gdt_idt
init_gdt_idt:
    ; Normally you would load GDT/IDT here using lgdt/lidt
    ret

