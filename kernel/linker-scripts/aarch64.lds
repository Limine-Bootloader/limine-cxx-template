/* Tell the linker that we want an aarch64 ELF64 output file */
OUTPUT_FORMAT(elf64-littleaarch64)

/* We want the symbol kmain to be our entry point */
ENTRY(kmain)

/* Define the program headers we want so the bootloader gives us the right */
/* MMU permissions; this also allows us to exert more control over the linking */
/* process. */
PHDRS
{
    limine_requests PT_LOAD FLAGS(0x06); /* Read, write */
    text PT_LOAD FLAGS(0x05); /* Read, execute */
    rodata PT_LOAD FLAGS(0x04); /* Read */
    data PT_LOAD FLAGS(0x06); /* Read, write */
}

SECTIONS
{
    /* We want to be placed in the topmost 2GiB of the address space, for optimisations */
    /* and because that is what the Limine spec mandates. */
    /* Any address in this region will do, but often 0xffffffff80000000 is chosen as */
    /* that is the beginning of the region. */
    . = 0xffffffff80000000;

    /* Define a section to contain the Limine requests and assign it to its own PHDR */
    .limine_requests : {
        KEEP(*(.limine_requests_start))
        KEEP(*(.limine_requests))
        KEEP(*(.limine_requests_end))
    } :limine_requests

    /* Move to the next memory page for .text */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .text : {
        *(.text .text.*)
    } :text

    /* Move to the next memory page for .rodata */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    /* Add a .note.gnu.build-id output section in case a build ID flag is added to the */
    /* linker command. */
    .note.gnu.build-id : {
        *(.note.gnu.build-id)
    } :rodata

    /* Move to the next memory page for .data */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    /* C++ is a language that allows for global constructors. In order to obtain the */
    /* address of the ".init_array" section we need to define a symbol for it. */
    /* The section is writable, so it needs to be mapped to :data. */
    /* GNU ld before 2.22 and gold before 2.27 cannot sort constructors by priority, */
    /* so we sort them by name a width at a time, as Clang does not pad priorities. */
    .init_array : {
        __init_array_start = .;
        KEEP(*(SORT(.init_array.?)))
        KEEP(*(SORT(.init_array.??)))
        KEEP(*(SORT(.init_array.???)))
        KEEP(*(SORT(.init_array.????)))
        KEEP(*(SORT(.init_array.?????)))
        KEEP(*(.init_array.*))
        KEEP(*(.init_array))
        __init_array_end = .;
    } :data

    /* Clang 10 and older emit constructors for x86 into .ctors instead, which we run */
    /* backwards: their names count down from 65535 by priority, so sorted by name */
    /* they run in priority order. */
    .ctors : {
        __ctors_start = .;
        KEEP(*(.ctors))
        KEEP(*(SORT(.ctors.*)))
        __ctors_end = .;
    } :data

    .data : {
        *(.data .data.*)
    } :data

    /* NOTE: .bss needs to be the last thing mapped to :data, otherwise lots of */
    /* unnecessary zeros will be written to the binary. */
    /* If you need, for example, .fini_array, it should be placed above this. */
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /* Discard .note.* and .eh_frame* since they may cause issues on some hosts, */
    /* the GOT, which nothing in the kernel needs but some linkers create, and */
    /* .ARM.attributes, which newer GCCs emit. */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
        *(.got .got.*)
        *(.ARM.attributes)
    }
}
