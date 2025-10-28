/* ----------------------------------------------------------------------
File: linker.lLinkerse: Linker script for the Pi OS 32-bit kernel.
Defines memory layout, entry point, and section placement.
*/
OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH(i386)
/* The kernel will be loaded by the bootloader at this memory address.
This is a common starting point for 32-bit protected mode kernels (1MB). */
ENTRY(_start)
KERNEL_START_ADDRESS = 0x100000;
SECTIONS
{
/* The main kernel binary will begin here. */
. = KERNEL_START_ADDRESS;
/* 1. .text Section (Code) */
/* All executable code and read-only data (like assembly constants) */
.text :
{
    *(.multiboot)           /* Ensure any multiboot header is placed first */
    *(.text)                /* All standard code goes here */
}

/* Align to the next page boundary */
. = ALIGN(0x1000); 

/* 2. .rodata Section (Read-Only Data) */
/* Place constant data here (e.g., string literals) */
.rodata :
{
    *(.rodata)
}

/* 3. .data Section (Initialized Data) */
/* Place global variables that have initial values */
.data :
{
    data_start = .;         /* Define symbol for start of data */
    *(.data)
    data_end = .;           /* Define symbol for end of data */
}

/* 4. .bss Section (Uninitialized Data) */
/* Global variables initialized to zero (or uninitialized) */
/* This section is defined but not physically present in the binary file. */
.bss :
{
    bss_start = .;          /* Define symbol for start of BSS */
    *(.bss)
    *(COMMON)               /* Common symbols often go into BSS */
    bss_end = .;            /* Define symbol for end of BSS */
}

/* Define a symbol pointing to the end of the entire kernel image in memory */
kernel_end = .;

/DISCARD/ :                 /* Discard any unwanted sections */
{
    *(.eh_frame)
}
