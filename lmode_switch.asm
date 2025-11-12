; ----------------------------------------------------------------------
; File: lmode_switch.asm
; Purpose: Transition the CPU from 32-bit Protected Mode to 64-bit Long Mode
; ----------------------------------------------------------------------

BITS 32

extern kernel_64bit_entry    ; 64-bit kernel entry symbol (defined in a 64-bit source)

; ----------------------------------------------------------------------
; Constants
; ----------------------------------------------------------------------
%define P_PRESENT_RW   0x003           ; Present + Writable
%define MSR_EFER       0xC0000080      ; IA32_EFER MSR index
%define EFER_LME_BIT   (1 << 8)        ; Long Mode Enable
%define CR4_PAE_BIT    (1 << 5)        ; PAE enable
%define CR0_PG_BIT     (1 << 31)       ; Paging enable
%define CR0_PE_BIT     (1 << 0)        ; Protection enable (already set in pmode)

; ----------------------------------------------------------------------
; Page tables (identity-map first 4 MiB with 4 KiB pages)
; Aligned to 4 KiB as required by hardware
; ----------------------------------------------------------------------
ALIGN 4096
pml4_table:
    ; PML4[0] -> PDPT | flags
    dq (pdp_table | P_PRESENT_RW)
    ; Fill remaining entries with 0
    times 511 dq 0

ALIGN 4096
pdp_table:
    ; PDPT[0] -> PD | flags
    dq (pd_table | P_PRESENT_RW)
    times 511 dq 0

ALIGN 4096
pd_table:
    ; PD[0] -> PT | flags
    dq (pt_table | P_PRESENT_RW)
    times 511 dq 0

ALIGN 4096
pt_table:
%assign i 0
%rep 1024
    ; PT[i] identity maps physical i*4KiB with present+write
    dq ((i * 4096) | P_PRESENT_RW)
%assign i i + 1
%endrep

; ----------------------------------------------------------------------
; 64-bit GDT
; We need at minimum: null, 64-bit code, and data segments.
; Selector 0x08 will be the 64-bit code segment.
; ----------------------------------------------------------------------
ALIGN 8
gdt64:
    dq 0x0000000000000000              ; Null
    ; 64-bit code segment: base=0, limit=0, flags set for code, L-bit=1
    dq 0x00AF9A000000FFFF              ; Commonly used; workable for long mode entry
    ; 64-bit data segment
    dq 0x00AF92000000FFFF

gdt64_end:

gdt_64bit_descriptor:
    dw gdt64_end - gdt64 - 1
    dd gdt64
    ; On x86, lgdt uses a 6-byte descriptor in 32-bit mode:
    ; [limit:2][base:4]

; ----------------------------------------------------------------------
; switch_to_lmode: enter 64-bit long mode and jump to kernel_64bit_entry
; ----------------------------------------------------------------------
global switch_to_lmode
switch_to_lmode:
    pushad

    ; 1) Load 64-bit GDT (still executed in 32-bit mode)
    lgdt [gdt_64bit_descriptor]

    ; 2) Load PML4 base into CR3 (physical address of pml4_table)
    mov eax, pml4_table
    mov cr3, eax

    ; 3) Enable PAE
    mov eax, cr4
    or eax, CR4_PAE_BIT
    mov cr4, eax

    ; 4) Enable Long Mode in EFER (set LME)
    mov ecx, MSR_EFER
    rdmsr                      ; EDX:EAX = EFER
    or eax, EFER_LME_BIT
    wrmsr

    ; 5) Enable paging (PG) — we are already in protected mode (PE)
    mov eax, cr0
    or eax, CR0_PG_BIT | CR0_PE_BIT
    mov cr0, eax

    ; 6) Far jump to 64-bit code segment: selector 0x08
    ; This transition sets CS to 0x08 and changes CPU to long mode
    jmp 0x08:kernel_64bit_entry

.hang:
    jmp .hang
