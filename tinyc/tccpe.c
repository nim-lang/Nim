/*
 *  TCCPE.C - PE file output for the Tiny C Compiler
 *
 *  Copyright (c) 2005-2007 grischka
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifdef TCC_TARGET_PE

#define ST_FN static
#define ST_DATA static
#define PUB_FN

#ifndef _WIN32
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

#define PE_MERGE_DATA
// #define PE_PRINT_SECTIONS

/* ----------------------------------------------------------- */
#ifndef IMAGE_NT_SIGNATURE
/* ----------------------------------------------------------- */
/* definitions below are from winnt.h */

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;
#pragma pack(push, 1)

typedef struct _IMAGE_DOS_HEADER {  /* DOS .EXE header */
    WORD e_magic;         /* Magic number */
    WORD e_cblp;          /* Bytes on last page of file */
    WORD e_cp;            /* Pages in file */
    WORD e_crlc;          /* Relocations */
    WORD e_cparhdr;       /* Size of header in paragraphs */
    WORD e_minalloc;      /* Minimum extra paragraphs needed */
    WORD e_maxalloc;      /* Maximum extra paragraphs needed */
    WORD e_ss;            /* Initial (relative) SS value */
    WORD e_sp;            /* Initial SP value */
    WORD e_csum;          /* Checksum */
    WORD e_ip;            /* Initial IP value */
    WORD e_cs;            /* Initial (relative) CS value */
    WORD e_lfarlc;        /* File address of relocation table */
    WORD e_ovno;          /* Overlay number */
    WORD e_res[4];        /* Reserved words */
    WORD e_oemid;         /* OEM identifier (for e_oeminfo) */
    WORD e_oeminfo;       /* OEM information; e_oemid specific */
    WORD e_res2[10];      /* Reserved words */
    DWORD e_lfanew;        /* File address of new exe header */
} IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER;

#define IMAGE_NT_SIGNATURE  0x00004550  /* PE00 */
#define SIZE_OF_NT_SIGNATURE 4

typedef struct _IMAGE_FILE_HEADER {
    WORD    Machine;
    WORD    NumberOfSections;
    DWORD   TimeDateStamp;
    DWORD   PointerToSymbolTable;
    DWORD   NumberOfSymbols;
    WORD    SizeOfOptionalHeader;
    WORD    Characteristics;
} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;


#define IMAGE_SIZEOF_FILE_HEADER 20

typedef struct _IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;
    DWORD   Size;
} IMAGE_DATA_DIRECTORY, *PIMAGE_DATA_DIRECTORY;


typedef struct _IMAGE_OPTIONAL_HEADER {
    /* Standard fields. */
    WORD    Magic;
    BYTE    MajorLinkerVersion;
    BYTE    MinorLinkerVersion;
    DWORD   SizeOfCode;
    DWORD   SizeOfInitializedData;
    DWORD   SizeOfUninitializedData;
    DWORD   AddressOfEntryPoint;
    DWORD   BaseOfCode;
    DWORD   BaseOfData;

    /* NT additional fields. */
    DWORD   ImageBase;
    DWORD   SectionAlignment;
    DWORD   FileAlignment;
    WORD    MajorOperatingSystemVersion;
    WORD    MinorOperatingSystemVersion;
    WORD    MajorImageVersion;
    WORD    MinorImageVersion;
    WORD    MajorSubsystemVersion;
    WORD    MinorSubsystemVersion;
    DWORD   Win32VersionValue;
    DWORD   SizeOfImage;
    DWORD   SizeOfHeaders;
    DWORD   CheckSum;
    WORD    Subsystem;
    WORD    DllCharacteristics;
    DWORD   SizeOfStackReserve;
    DWORD   SizeOfStackCommit;
    DWORD   SizeOfHeapReserve;
    DWORD   SizeOfHeapCommit;
    DWORD   LoaderFlags;
    DWORD   NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[16];

} IMAGE_OPTIONAL_HEADER, *PIMAGE_OPTIONAL_HEADER;


#define IMAGE_DIRECTORY_ENTRY_EXPORT          0   /* Export Directory */
#define IMAGE_DIRECTORY_ENTRY_IMPORT          1   /* Import Directory */
#define IMAGE_DIRECTORY_ENTRY_RESOURCE        2   /* Resource Directory */
#define IMAGE_DIRECTORY_ENTRY_EXCEPTION       3   /* Exception Directory */
#define IMAGE_DIRECTORY_ENTRY_SECURITY        4   /* Security Directory */
#define IMAGE_DIRECTORY_ENTRY_BASERELOC       5   /* Base Relocation Table */
#define IMAGE_DIRECTORY_ENTRY_DEBUG           6   /* Debug Directory */
/*      IMAGE_DIRECTORY_ENTRY_COPYRIGHT       7      (X86 usage) */
#define IMAGE_DIRECTORY_ENTRY_ARCHITECTURE    7   /* Architecture Specific Data */
#define IMAGE_DIRECTORY_ENTRY_GLOBALPTR       8   /* RVA of GP */
#define IMAGE_DIRECTORY_ENTRY_TLS             9   /* TLS Directory */
#define IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG    10   /* Load Configuration Directory */
#define IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT   11   /* Bound Import Directory in headers */
#define IMAGE_DIRECTORY_ENTRY_IAT            12   /* Import Address Table */
#define IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT   13   /* Delay Load Import Descriptors */
#define IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR 14   /* COM Runtime descriptor */

/* Section header format. */
#define IMAGE_SIZEOF_SHORT_NAME         8

typedef struct _IMAGE_SECTION_HEADER {
    BYTE    Name[IMAGE_SIZEOF_SHORT_NAME];
    union {
            DWORD   PhysicalAddress;
            DWORD   VirtualSize;
    } Misc;
    DWORD   VirtualAddress;
    DWORD   SizeOfRawData;
    DWORD   PointerToRawData;
    DWORD   PointerToRelocations;
    DWORD   PointerToLinenumbers;
    WORD    NumberOfRelocations;
    WORD    NumberOfLinenumbers;
    DWORD   Characteristics;
} IMAGE_SECTION_HEADER, *PIMAGE_SECTION_HEADER;

#define IMAGE_SIZEOF_SECTION_HEADER     40

typedef struct _IMAGE_BASE_RELOCATION {
    DWORD   VirtualAddress;
    DWORD   SizeOfBlock;
//  WORD    TypeOffset[1];
} IMAGE_BASE_RELOCATION;

#define IMAGE_SIZEOF_BASE_RELOCATION     8

#define IMAGE_REL_BASED_ABSOLUTE         0
#define IMAGE_REL_BASED_HIGH             1
#define IMAGE_REL_BASED_LOW              2
#define IMAGE_REL_BASED_HIGHLOW          3
#define IMAGE_REL_BASED_HIGHADJ          4
#define IMAGE_REL_BASED_MIPS_JMPADDR     5
#define IMAGE_REL_BASED_SECTION          6
#define IMAGE_REL_BASED_REL32            7

#pragma pack(pop)

/* ----------------------------------------------------------- */
#endif /* ndef IMAGE_NT_SIGNATURE */
/* ----------------------------------------------------------- */

#pragma pack(push, 1)

struct pe_header
{
    IMAGE_DOS_HEADER doshdr;
    BYTE dosstub[0x40];
    DWORD nt_sig;
    IMAGE_FILE_HEADER filehdr;
    IMAGE_OPTIONAL_HEADER opthdr;
};

struct pe_import_header {
    DWORD first_entry;
    DWORD time_date;
    DWORD forwarder;
    DWORD lib_name_offset;
    DWORD first_thunk;
};

struct pe_export_header {
    DWORD Characteristics;
    DWORD TimeDateStamp;
    DWORD Version;
    DWORD Name;
    DWORD Base;
    DWORD NumberOfFunctions;
    DWORD NumberOfNames;
    DWORD AddressOfFunctions;
    DWORD AddressOfNames;
    DWORD AddressOfNameOrdinals;
};

struct pe_reloc_header {
    DWORD offset;
    DWORD size;
};

struct pe_rsrc_header {
    struct _IMAGE_FILE_HEADER filehdr;
    struct _IMAGE_SECTION_HEADER sectionhdr;
};

struct pe_rsrc_reloc {
    DWORD offset;
    DWORD size;
    WORD type;
};

#pragma pack(pop)

/* ----------------------------------------------------------- */
ST_DATA struct pe_header pe_header = {
{
    /* IMAGE_DOS_HEADER doshdr */
    0x5A4D, /*WORD e_magic;         Magic number */
    0x0090, /*WORD e_cblp;          Bytes on last page of file */
    0x0003, /*WORD e_cp;            Pages in file */
    0x0000, /*WORD e_crlc;          Relocations */

    0x0004, /*WORD e_cparhdr;       Size of header in paragraphs */
    0x0000, /*WORD e_minalloc;      Minimum extra paragraphs needed */
    0xFFFF, /*WORD e_maxalloc;      Maximum extra paragraphs needed */
    0x0000, /*WORD e_ss;            Initial (relative) SS value */

    0x00B8, /*WORD e_sp;            Initial SP value */
    0x0000, /*WORD e_csum;          Checksum */
    0x0000, /*WORD e_ip;            Initial IP value */
    0x0000, /*WORD e_cs;            Initial (relative) CS value */
    0x0040, /*WORD e_lfarlc;        File address of relocation table */
    0x0000, /*WORD e_ovno;          Overlay number */
    {0,0,0,0}, /*WORD e_res[4];     Reserved words */
    0x0000, /*WORD e_oemid;         OEM identifier (for e_oeminfo) */
    0x0000, /*WORD e_oeminfo;       OEM information; e_oemid specific */
    {0,0,0,0,0,0,0,0,0,0}, /*WORD e_res2[10];      Reserved words */
    0x00000080  /*DWORD   e_lfanew;        File address of new exe header */
},{
    /* BYTE dosstub[0x40] */
    /* 14 code bytes + "This program cannot be run in DOS mode.\r\r\n$" + 6 * 0x00 */
    0x0e,0x1f,0xba,0x0e,0x00,0xb4,0x09,0xcd,0x21,0xb8,0x01,0x4c,0xcd,0x21,0x54,0x68,
    0x69,0x73,0x20,0x70,0x72,0x6f,0x67,0x72,0x61,0x6d,0x20,0x63,0x61,0x6e,0x6e,0x6f,
    0x74,0x20,0x62,0x65,0x20,0x72,0x75,0x6e,0x20,0x69,0x6e,0x20,0x44,0x4f,0x53,0x20,
    0x6d,0x6f,0x64,0x65,0x2e,0x0d,0x0d,0x0a,0x24,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
},
    0x00004550, /* DWORD nt_sig = IMAGE_NT_SIGNATURE */
{
    /* IMAGE_FILE_HEADER filehdr */
    0x014C, /*WORD    Machine; */
    0x0003, /*WORD    NumberOfSections; */
    0x00000000, /*DWORD   TimeDateStamp; */
    0x00000000, /*DWORD   PointerToSymbolTable; */
    0x00000000, /*DWORD   NumberOfSymbols; */
    0x00E0, /*WORD    SizeOfOptionalHeader; */
    0x030F  /*WORD    Characteristics; */
},{
    /* IMAGE_OPTIONAL_HEADER opthdr */
    /* Standard fields. */
    0x010B, /*WORD    Magic; */
    0x06, /*BYTE    MajorLinkerVersion; */
    0x00, /*BYTE    MinorLinkerVersion; */
    0x00000000, /*DWORD   SizeOfCode; */
    0x00000000, /*DWORD   SizeOfInitializedData; */
    0x00000000, /*DWORD   SizeOfUninitializedData; */
    0x00000000, /*DWORD   AddressOfEntryPoint; */
    0x00000000, /*DWORD   BaseOfCode; */
    0x00000000, /*DWORD   BaseOfData; */

    /* NT additional fields. */
    0x00400000, /*DWORD   ImageBase; */
    0x00001000, /*DWORD   SectionAlignment; */
    0x00000200, /*DWORD   FileAlignment; */
    0x0004, /*WORD    MajorOperatingSystemVersion; */
    0x0000, /*WORD    MinorOperatingSystemVersion; */
    0x0000, /*WORD    MajorImageVersion; */
    0x0000, /*WORD    MinorImageVersion; */
    0x0004, /*WORD    MajorSubsystemVersion; */
    0x0000, /*WORD    MinorSubsystemVersion; */
    0x00000000, /*DWORD   Win32VersionValue; */
    0x00000000, /*DWORD   SizeOfImage; */
    0x00000200, /*DWORD   SizeOfHeaders; */
    0x00000000, /*DWORD   CheckSum; */
    0x0002, /*WORD    Subsystem; */
    0x0000, /*WORD    DllCharacteristics; */
    0x00100000, /*DWORD   SizeOfStackReserve; */
    0x00001000, /*DWORD   SizeOfStackCommit; */
    0x00100000, /*DWORD   SizeOfHeapReserve; */
    0x00001000, /*DWORD   SizeOfHeapCommit; */
    0x00000000, /*DWORD   LoaderFlags; */
    0x00000010, /*DWORD   NumberOfRvaAndSizes; */

    /* IMAGE_DATA_DIRECTORY DataDirectory[16]; */
    {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0},
     {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}}
}};

/* ------------------------------------------------------------- */
/* internal temporary structures */

/*
#define IMAGE_SCN_CNT_CODE                  0x00000020
#define IMAGE_SCN_CNT_INITIALIZED_DATA      0x00000040
#define IMAGE_SCN_CNT_UNINITIALIZED_DATA    0x00000080
#define IMAGE_SCN_MEM_DISCARDABLE           0x02000000
#define IMAGE_SCN_MEM_SHARED                0x10000000
#define IMAGE_SCN_MEM_EXECUTE               0x20000000
#define IMAGE_SCN_MEM_READ                  0x40000000
#define IMAGE_SCN_MEM_WRITE                 0x80000000
*/

enum {
    sec_text = 0,
    sec_data ,
    sec_bss ,
    sec_idata ,
    sec_other ,
    sec_rsrc ,
    sec_stab ,
    sec_reloc ,
    sec_last
};

ST_DATA DWORD pe_sec_flags[] = {
    0x60000020, /* ".text"     , */
    0xC0000040, /* ".data"     , */
    0xC0000080, /* ".bss"      , */
    0x40000040, /* ".idata"    , */
    0xE0000060, /* < other >   , */
    0x40000040, /* ".rsrc"     , */
    0x42000802, /* ".stab"     , */
    0x42000040, /* ".reloc"    , */
};

struct section_info {
    int cls, ord;
    char name[32];
    DWORD sh_addr;
    DWORD sh_size;
    DWORD sh_flags;
    unsigned char *data;
    DWORD data_size;
    IMAGE_SECTION_HEADER ish;
};

struct import_symbol {
    int sym_index;
    int iat_index;
    int thk_offset;
};

struct pe_import_info {
    int dll_index;
    int sym_count;
    struct import_symbol **symbols;
};

struct pe_info {
    TCCState *s1;
    Section *reloc;
    Section *thunk;
    const char *filename;
    int type;
    DWORD sizeofheaders;
    DWORD imagebase;
    DWORD start_addr;
    DWORD imp_offs;
    DWORD imp_size;
    DWORD iat_offs;
    DWORD iat_size;
    DWORD exp_offs;
    DWORD exp_size;
    struct section_info *sec_info;
    int sec_count;
    struct pe_import_info **imp_info;
    int imp_count;
};

/* ------------------------------------------------------------- */

#define PE_NUL 0
#define PE_DLL 1
#define PE_GUI 2
#define PE_EXE 3

void error_noabort(const char *, ...);

#ifdef _WIN32
void dbg_printf (const char *fmt, ...)
{
    char buffer[4000];
    va_list arg;
    int x;
    va_start(arg, fmt);
    x = vsprintf (buffer, fmt, arg);
    strcpy(buffer+x, "\n");
    OutputDebugString(buffer);
}
#endif

/* --------------------------------------------*/

ST_FN const char* get_alt_symbol(char *buffer, const char *symbol)
{
    const char *p;
    p = strrchr(symbol, '@');
    if (p && isnum(p[1]) && symbol[0] == '_') { /* stdcall decor */
        strcpy(buffer, symbol+1)[p-symbol-1] = 0;
    } else if (symbol[0] != '_') { /* try non-ansi function */
        buffer[0] = '_', strcpy(buffer + 1, symbol);
    } else if (0 == memcmp(symbol, "__imp__", 7)) { /* mingw 2.0 */
        strcpy(buffer, symbol + 6);
    } else if (0 == memcmp(symbol, "_imp___", 7)) { /* mingw 3.7 */
        strcpy(buffer, symbol + 6);
    } else {
        return symbol;
    }
    return buffer;
}

ST_FN int pe_find_import(TCCState * s1, const char *symbol)
{
    char buffer[200];
    const char *s;
    int sym_index, n = 0;
    do {
        s = n ? get_alt_symbol(buffer, symbol) : symbol;
        sym_index = find_elf_sym(s1->dynsymtab_section, s);
        // printf("find %d %s\n", sym_index, s);
    } while (0 == sym_index && ++n < 2);
    return sym_index;
}

#if defined _WIN32 || defined __CYGWIN__

#ifdef __CYGWIN__
# include <dlfcn.h>
# define LoadLibrary(s) dlopen(s, RTLD_NOW)
# define GetProcAddress(h,s) dlsym(h, s)
#else
# define dlclose(h) FreeLibrary(h)
#endif

/* for the -run option: dynamically load symbol from dll */
void *resolve_sym(struct TCCState *s1, const char *symbol, int type)
{
    char buffer[100];
    int sym_index, dll_index;
    void *addr, **m;
    DLLReference *dllref;

    sym_index = pe_find_import(s1, symbol);
    if (0 == sym_index)
        return NULL;
    dll_index = ((Elf32_Sym *)s1->dynsymtab_section->data + sym_index)->st_value;
    dllref = s1->loaded_dlls[dll_index-1];
    if ( !dllref->handle )
    {
        dllref->handle = LoadLibrary(dllref->name);
    }
    addr = GetProcAddress(dllref->handle, symbol);
    if (NULL == addr)
        addr = GetProcAddress(dllref->handle, get_alt_symbol(buffer, symbol));

    if (addr && STT_OBJECT == type) {
        /* need to return a pointer to the address for data objects */
        m = (void**)tcc_malloc(sizeof addr), *m = addr, addr = m;
#ifdef MEM_DEBUG
        /* yep, we don't free it */
        mem_cur_size -= sizeof (void*);
#endif
    }
    return addr;
}
#endif

/*----------------------------------------------------------------------------*/

ST_FN int dynarray_assoc(void **pp, int n, int key)
{
    int i;
    for (i = 0; i < n; ++i, ++pp)
    if (key == **(int **) pp)
        return i;
    return -1;
}

#if 0
ST_FN DWORD umin(DWORD a, DWORD b)
{
    return a < b ? a : b;
}
#endif

ST_FN DWORD umax(DWORD a, DWORD b)
{
    return a < b ? b : a;
}

ST_FN void pe_fpad(FILE *fp, DWORD new_pos)
{
    DWORD pos = ftell(fp);
    while (++pos <= new_pos)
        fputc(0, fp);
}

ST_FN DWORD pe_file_align(DWORD n)
{
    return (n + (0x200 - 1)) & ~(0x200 - 1);
}

ST_FN DWORD pe_virtual_align(DWORD n)
{
    return (n + (0x1000 - 1)) & ~(0x1000 - 1);
}

ST_FN void pe_align_section(Section *s, int a)
{
    int i = s->data_offset & (a-1);
    if (i)
        section_ptr_add(s, a - i);
}

ST_FN void pe_set_datadir(int dir, DWORD addr, DWORD size)
{
    pe_header.opthdr.DataDirectory[dir].VirtualAddress = addr;
    pe_header.opthdr.DataDirectory[dir].Size = size;
}

/*----------------------------------------------------------------------------*/
ST_FN int pe_write(struct pe_info *pe)
{
    int i;
    FILE *op;
    DWORD file_offset, r;

    op = fopen(pe->filename, "wb");
    if (NULL == op) {
        error_noabort("could not write '%s': %s", pe->filename, strerror(errno));
        return 1;
    }

    pe->sizeofheaders = pe_file_align(
        sizeof pe_header
        + pe->sec_count * sizeof (IMAGE_SECTION_HEADER)
        );

    file_offset = pe->sizeofheaders;
    pe_fpad(op, file_offset);

    if (2 == pe->s1->verbose)
        printf("-------------------------------"
               "\n  virt   file   size  section" "\n");

    for (i = 0; i < pe->sec_count; ++i) {
        struct section_info *si = pe->sec_info + i;
        const char *sh_name = si->name;
        unsigned long addr = si->sh_addr - pe->imagebase;
        unsigned long size = si->sh_size;
        IMAGE_SECTION_HEADER *psh = &si->ish;

        if (2 == pe->s1->verbose)
            printf("%6lx %6lx %6lx  %s\n",
                addr, file_offset, size, sh_name);

        switch (si->cls) {
            case sec_text:
                pe_header.opthdr.BaseOfCode = addr;
                pe_header.opthdr.AddressOfEntryPoint = addr + pe->start_addr;
                break;

            case sec_data:
                pe_header.opthdr.BaseOfData = addr;
                break;

            case sec_bss:
                break;

            case sec_reloc:
                pe_set_datadir(IMAGE_DIRECTORY_ENTRY_BASERELOC, addr, size);
                break;

            case sec_rsrc:
                pe_set_datadir(IMAGE_DIRECTORY_ENTRY_RESOURCE, addr, size);
                break;

            case sec_stab:
                break;
        }

        if (pe->thunk == pe->s1->sections[si->ord]) {
            if (pe->imp_size) {
                pe_set_datadir(IMAGE_DIRECTORY_ENTRY_IMPORT,
                    pe->imp_offs + addr, pe->imp_size);
                pe_set_datadir(IMAGE_DIRECTORY_ENTRY_IAT,
                    pe->iat_offs + addr, pe->iat_size);
            }
            if (pe->exp_size) {
                pe_set_datadir(IMAGE_DIRECTORY_ENTRY_EXPORT,
                    pe->exp_offs + addr, pe->exp_size);
            }
        }

        strcpy((char*)psh->Name, sh_name);

        psh->Characteristics = pe_sec_flags[si->cls];
        psh->VirtualAddress = addr;
        psh->Misc.VirtualSize = size;
        pe_header.opthdr.SizeOfImage =
            umax(pe_virtual_align(size + addr), pe_header.opthdr.SizeOfImage); 

        if (si->data_size) {
            psh->PointerToRawData = r = file_offset;
            fwrite(si->data, 1, si->data_size, op);
            file_offset = pe_file_align(file_offset + si->data_size);
            psh->SizeOfRawData = file_offset - r;
            pe_fpad(op, file_offset);
        }
    }

    // pe_header.filehdr.TimeDateStamp = time(NULL);
    pe_header.filehdr.NumberOfSections = pe->sec_count;
    pe_header.opthdr.SizeOfHeaders = pe->sizeofheaders;
    pe_header.opthdr.ImageBase = pe->imagebase;
    if (PE_DLL == pe->type)
        pe_header.filehdr.Characteristics = 0x230E;
    else if (PE_GUI != pe->type)
        pe_header.opthdr.Subsystem = 3;

    fseek(op, SEEK_SET, 0);
    fwrite(&pe_header,  1, sizeof pe_header, op);
    for (i = 0; i < pe->sec_count; ++i)
        fwrite(&pe->sec_info[i].ish, 1, sizeof(IMAGE_SECTION_HEADER), op);
    fclose (op);

    if (2 == pe->s1->verbose)
        printf("-------------------------------\n");
    if (pe->s1->verbose)
        printf("<- %s (%lu bytes)\n", pe->filename, file_offset);

    return 0;
}

/*----------------------------------------------------------------------------*/

ST_FN struct import_symbol *pe_add_import(struct pe_info *pe, int sym_index)
{
    int i;
    int dll_index;
    struct pe_import_info *p;
    struct import_symbol *s;

    dll_index = ((Elf32_Sym *)pe->s1->dynsymtab_section->data + sym_index)->st_value;
    if (0 == dll_index)
        return NULL;

    i = dynarray_assoc ((void**)pe->imp_info, pe->imp_count, dll_index);
    if (-1 != i) {
        p = pe->imp_info[i];
        goto found_dll;
    }
    p = tcc_mallocz(sizeof *p);
    p->dll_index = dll_index;
    dynarray_add((void***)&pe->imp_info, &pe->imp_count, p);

found_dll:
    i = dynarray_assoc ((void**)p->symbols, p->sym_count, sym_index);
    if (-1 != i)
        return p->symbols[i];

    s = tcc_mallocz(sizeof *s);
    dynarray_add((void***)&p->symbols, &p->sym_count, s);
    s->sym_index = sym_index;
    return s;
}

/*----------------------------------------------------------------------------*/
ST_FN void pe_build_imports(struct pe_info *pe)
{
    int thk_ptr, ent_ptr, dll_ptr, sym_cnt, i;
    DWORD rva_base = pe->thunk->sh_addr - pe->imagebase;
    int ndlls = pe->imp_count;

    for (sym_cnt = i = 0; i < ndlls; ++i)
        sym_cnt += pe->imp_info[i]->sym_count;

    if (0 == sym_cnt)
        return;

    pe_align_section(pe->thunk, 16);

    pe->imp_offs = dll_ptr = pe->thunk->data_offset;
    pe->imp_size = (ndlls + 1) * sizeof(struct pe_import_header);
    pe->iat_offs = dll_ptr + pe->imp_size;
    pe->iat_size = (sym_cnt + ndlls) * sizeof(DWORD);
    section_ptr_add(pe->thunk, pe->imp_size + 2*pe->iat_size);

    thk_ptr = pe->iat_offs;
    ent_ptr = pe->iat_offs + pe->iat_size;

    for (i = 0; i < pe->imp_count; ++i) {
        struct pe_import_header *hdr;
        int k, n, v;
        struct pe_import_info *p = pe->imp_info[i];
        const char *name = pe->s1->loaded_dlls[p->dll_index-1]->name;

        /* put the dll name into the import header */
        v = put_elf_str(pe->thunk, name);

        hdr = (struct pe_import_header*)(pe->thunk->data + dll_ptr);
        hdr->first_thunk     = thk_ptr + rva_base;
        hdr->first_entry     = ent_ptr + rva_base;
        hdr->lib_name_offset = v + rva_base;

        for (k = 0, n = p->sym_count; k <= n; ++k) {
            if (k < n) {
                DWORD iat_index = p->symbols[k]->iat_index;
                int sym_index = p->symbols[k]->sym_index;
                Elf32_Sym *imp_sym = (Elf32_Sym *)pe->s1->dynsymtab_section->data + sym_index;
                Elf32_Sym *org_sym = (Elf32_Sym *)symtab_section->data + iat_index;
                const char *name = pe->s1->dynsymtab_section->link->data + imp_sym->st_name;

                org_sym->st_value = thk_ptr;
                org_sym->st_shndx = pe->thunk->sh_num;
                v = pe->thunk->data_offset + rva_base;
                section_ptr_add(pe->thunk, sizeof(WORD)); /* hint, not used */
                put_elf_str(pe->thunk, name);

            } else {
                v = 0; /* last entry is zero */
            }
            *(DWORD*)(pe->thunk->data+thk_ptr) =
            *(DWORD*)(pe->thunk->data+ent_ptr) = v;
            thk_ptr += sizeof (DWORD);
            ent_ptr += sizeof (DWORD);
        }
        dll_ptr += sizeof(struct pe_import_header);
        dynarray_reset(&p->symbols, &p->sym_count);
    }
    dynarray_reset(&pe->imp_info, &pe->imp_count);
}

/* ------------------------------------------------------------- */
/*
    For now only functions are exported. Export of data
    would work, but import requires compiler support to
    do an additional indirection.

    For instance:
        __declspec(dllimport) extern int something;

    needs to be translated to:

        *(int*)something
*/

ST_FN int sym_cmp(const void *va, const void *vb)
{
    const char *ca = ((const char **)va)[1];
    const char *cb = ((const char **)vb)[1];
    return strcmp(ca, cb);
}

ST_FN void pe_build_exports(struct pe_info *pe)
{
    Elf32_Sym *sym;
    int sym_index, sym_end;
    DWORD rva_base, func_o, name_o, ord_o, str_o;
    struct pe_export_header *hdr;
    int sym_count, n, ord, *sorted, *sp;

    FILE *op;
    char buf[MAX_PATH];
    const char *dllname;
    const char *name;

    rva_base = pe->thunk->sh_addr - pe->imagebase;
    sym_count = 0, n = 1, sorted = NULL, op = NULL;

    sym_end = symtab_section->data_offset / sizeof(Elf32_Sym);
    for (sym_index = 1; sym_index < sym_end; ++sym_index) {
        sym = (Elf32_Sym*)symtab_section->data + sym_index;
        name = symtab_section->link->data + sym->st_name;
        if ((sym->st_other & 1)
            /* export only symbols from actually written sections */
            && pe->s1->sections[sym->st_shndx]->sh_addr) {
            dynarray_add((void***)&sorted, &sym_count, (void*)n);
            dynarray_add((void***)&sorted, &sym_count, (void*)name);
        }
        ++n;
#if 0
        if (sym->st_other & 1)
            printf("export: %s\n", name);
        if (sym->st_other & 2)
            printf("stdcall: %s\n", name);
#endif
    }

    if (0 == sym_count)
        return;
    sym_count /= 2;

    qsort (sorted, sym_count, 2 * sizeof sorted[0], sym_cmp);
    pe_align_section(pe->thunk, 16);
    dllname = tcc_basename(pe->filename);

    pe->exp_offs = pe->thunk->data_offset;
    func_o = pe->exp_offs + sizeof(struct pe_export_header);
    name_o = func_o + sym_count * sizeof (DWORD);
    ord_o = name_o + sym_count * sizeof (DWORD);
    str_o = ord_o + sym_count * sizeof(WORD);

    hdr = section_ptr_add(pe->thunk, str_o - pe->exp_offs);
    hdr->Characteristics        = 0;
    hdr->Base                   = 1;
    hdr->NumberOfFunctions      = sym_count;
    hdr->NumberOfNames          = sym_count;
    hdr->AddressOfFunctions     = func_o + rva_base;
    hdr->AddressOfNames         = name_o + rva_base;
    hdr->AddressOfNameOrdinals  = ord_o + rva_base;
    hdr->Name                   = str_o + rva_base;
    put_elf_str(pe->thunk, dllname);

#if 1
    /* automatically write exports to <output-filename>.def */
    strcpy(buf, pe->filename);
    strcpy(tcc_fileextension(buf), ".def");
    op = fopen(buf, "w");
    if (NULL == op) {
        error_noabort("could not create '%s': %s", buf, strerror(errno));
    } else {
        fprintf(op, "LIBRARY %s\n\nEXPORTS\n", dllname);
        if (pe->s1->verbose)
            printf("<- %s (%d symbols)\n", buf, sym_count);
    }
#endif

    for (sp = sorted, ord = 0; ord < sym_count; ++ord, sp += 2)
    {
        sym_index = sp[0], name = (const char *)sp[1];
        /* insert actual address later in pe_relocate_rva */
        put_elf_reloc(symtab_section, pe->thunk,
            func_o, R_386_RELATIVE, sym_index);
        *(DWORD*)(pe->thunk->data + name_o)
            = pe->thunk->data_offset + rva_base;
        *(WORD*)(pe->thunk->data + ord_o)
            = ord;
        put_elf_str(pe->thunk, name);
        func_o += sizeof (DWORD);
        name_o += sizeof (DWORD);
        ord_o += sizeof (WORD);

        if (op)
            fprintf(op, "%s\n", name);
    }
    pe->exp_size = pe->thunk->data_offset - pe->exp_offs;
    tcc_free(sorted);
}

/* ------------------------------------------------------------- */
ST_FN void pe_build_reloc (struct pe_info *pe)
{
    DWORD offset, block_ptr, addr;
    int count, i;
    Elf32_Rel *rel, *rel_end;
    Section *s = NULL, *sr;

    offset = addr = block_ptr = count = i = 0;
    rel = rel_end = NULL;

    for(;;) {
        if (rel < rel_end) {
            int type = ELF32_R_TYPE(rel->r_info);
            addr = rel->r_offset + s->sh_addr;
            ++ rel;
            if (type != R_386_32)
                continue;
            if (count == 0) { /* new block */
                block_ptr = pe->reloc->data_offset;
                section_ptr_add(pe->reloc, sizeof(struct pe_reloc_header));
                offset = addr & 0xFFFFFFFF<<12;
            }
            if ((addr -= offset)  < (1<<12)) { /* one block spans 4k addresses */
                WORD *wp = section_ptr_add(pe->reloc, sizeof (WORD));
                *wp = addr | IMAGE_REL_BASED_HIGHLOW<<12;
                ++count;
                continue;
            }
            -- rel;

        } else if (i < pe->sec_count) {
            sr = (s = pe->s1->sections[pe->sec_info[i++].ord])->reloc;
            if (sr) {
                rel = (Elf32_Rel *)sr->data;
                rel_end = (Elf32_Rel *)(sr->data + sr->data_offset);
            }
            continue;
        }

        if (count) {
            /* store the last block and ready for a new one */
            struct pe_reloc_header *hdr;
            if (count & 1) /* align for DWORDS */
                section_ptr_add(pe->reloc, sizeof(WORD)), ++count;
            hdr = (struct pe_reloc_header *)(pe->reloc->data + block_ptr);
            hdr -> offset = offset - pe->imagebase;
            hdr -> size = count * sizeof(WORD) + sizeof(struct pe_reloc_header);
            count = 0;
        }

        if (rel >= rel_end)
            break;
    }
}

/* ------------------------------------------------------------- */
ST_FN int pe_section_class(Section *s)
{
    int type, flags;
    const char *name;

    type = s->sh_type;
    flags = s->sh_flags;
    name = s->name;
    if (flags & SHF_ALLOC) {
        if (type == SHT_PROGBITS) {
            if (flags & SHF_EXECINSTR)
                return sec_text;
            if (flags & SHF_WRITE)
                return sec_data;
            if (0 == strcmp(name, ".rsrc"))
                return sec_rsrc;
            if (0 == strcmp(name, ".iedat"))
                return sec_idata;
            return sec_other;
        } else if (type == SHT_NOBITS) {
            if (flags & SHF_WRITE)
                return sec_bss;
        }
    } else {
        if (0 == strcmp(name, ".reloc"))
            return sec_reloc;
        if (0 == strncmp(name, ".stab", 5)) /* .stab and .stabstr */
            return sec_stab;
    }
    return -1;
}

ST_FN int pe_assign_addresses (struct pe_info *pe)
{
    int i, k, o, c;
    DWORD addr;
    int *section_order;
    struct section_info *si;
    Section *s;

    // pe->thunk = new_section(pe->s1, ".iedat", SHT_PROGBITS, SHF_ALLOC);

    section_order = tcc_malloc(pe->s1->nb_sections * sizeof (int));
    for (o = k = 0 ; k < sec_last; ++k) {
        for (i = 1; i < pe->s1->nb_sections; ++i) {
            s = pe->s1->sections[i];
            if (k == pe_section_class(s)) {
                // printf("%s %d\n", s->name, k);
                s->sh_addr = pe->imagebase;
                section_order[o++] = i;
            }
        }
    }

    pe->sec_info = tcc_mallocz(o * sizeof (struct section_info));
    addr = pe->imagebase + 1;

    for (i = 0; i < o; ++i)
    {
        k = section_order[i];
        s = pe->s1->sections[k];
        c = pe_section_class(s);
        si = &pe->sec_info[pe->sec_count];

#ifdef PE_MERGE_DATA
        if (c == sec_bss && pe->sec_count && si[-1].cls == sec_data) {
            /* append .bss to .data */
            s->sh_addr = addr = ((addr-1) | 15) + 1;
            addr += s->data_offset;
            si[-1].sh_size = addr - si[-1].sh_addr;
            continue;
        }
#endif
        strcpy(si->name, s->name);
        si->cls = c;
        si->ord = k;
        si->sh_addr = s->sh_addr = addr = pe_virtual_align(addr);
        si->sh_flags = s->sh_flags;

        if (c == sec_data && NULL == pe->thunk)
            pe->thunk = s;

        if (s == pe->thunk) {
            pe_build_imports(pe);
            pe_build_exports(pe);
        }

        if (c == sec_reloc)
            pe_build_reloc (pe);

        if (s->data_offset)
        {
            if (s->sh_type != SHT_NOBITS) {
                si->data = s->data;
                si->data_size = s->data_offset;
            }

            addr += s->data_offset;
            si->sh_size = s->data_offset;
            ++pe->sec_count;
        }
        // printf("%08x %05x %s\n", si->sh_addr, si->sh_size, si->name);
    }

#if 0
    for (i = 1; i < pe->s1->nb_sections; ++i) {
        Section *s = pe->s1->sections[i];
        int type = s->sh_type;
        int flags = s->sh_flags;
        printf("section %-16s %-10s %5x %s,%s,%s\n",
            s->name,
            type == SHT_PROGBITS ? "progbits" :
            type == SHT_NOBITS ? "nobits" :
            type == SHT_SYMTAB ? "symtab" :
            type == SHT_STRTAB ? "strtab" :
            type == SHT_REL ? "rel" : "???",
            s->data_offset,
            flags & SHF_ALLOC ? "alloc" : "",
            flags & SHF_WRITE ? "write" : "",
            flags & SHF_EXECINSTR ? "exec" : ""
            );
    }
    pe->s1->verbose = 2;
#endif

    tcc_free(section_order);
    return 0;
}

/* ------------------------------------------------------------- */
ST_FN void pe_relocate_rva (struct pe_info *pe, Section *s)
{
    Section *sr = s->reloc;
    Elf32_Rel *rel, *rel_end;
    rel_end = (Elf32_Rel *)(sr->data + sr->data_offset);
    for(rel = (Elf32_Rel *)sr->data; rel < rel_end; rel++)
        if (ELF32_R_TYPE(rel->r_info) == R_386_RELATIVE) {
            int sym_index = ELF32_R_SYM(rel->r_info);
            DWORD addr = s->sh_addr;
            if (sym_index) {
                Elf32_Sym *sym = (Elf32_Sym *)symtab_section->data + sym_index;
                addr = sym->st_value;
            }
            *(DWORD*)(s->data + rel->r_offset) += addr - pe->imagebase;
        }
}

/*----------------------------------------------------------------------------*/
ST_FN int pe_check_symbols(struct pe_info *pe)
{
    Elf32_Sym *sym;
    int sym_index, sym_end;
    int ret = 0;

    pe_align_section(text_section, 8);

    sym_end = symtab_section->data_offset / sizeof(Elf32_Sym);
    for (sym_index = 1; sym_index < sym_end; ++sym_index) {

        sym = (Elf32_Sym*)symtab_section->data + sym_index;
        if (sym->st_shndx == SHN_UNDEF) {

            const char *name = symtab_section->link->data + sym->st_name;
            unsigned type = ELF32_ST_TYPE(sym->st_info);
            int imp_sym = pe_find_import(pe->s1, name);
            struct import_symbol *is;

            if (0 == imp_sym)
                goto not_found;
            is = pe_add_import(pe, imp_sym);
            if (!is)
                goto not_found;

            if (type == STT_FUNC) {
                unsigned long offset = is->thk_offset;
                if (offset) {
                    /* got aliased symbol, like stricmp and _stricmp */

                } else {
                    char buffer[100];

                    offset = text_section->data_offset;
                    /* add the 'jmp IAT[x]' instruction */
                    *(WORD*)section_ptr_add(text_section, 8) = 0x25FF;

                    /* add a helper symbol, will be patched later in
                       pe_build_imports */
                    sprintf(buffer, "IAT.%s", name);
                    is->iat_index = put_elf_sym(
                        symtab_section, 0, sizeof(DWORD),
                        ELF32_ST_INFO(STB_GLOBAL, STT_OBJECT),
                        0, SHN_UNDEF, buffer);
                    put_elf_reloc(symtab_section, text_section, 
                        offset + 2, R_386_32, is->iat_index);
                    is->thk_offset = offset;
                }

                /* tcc_realloc might have altered sym's address */
                sym = (Elf32_Sym*)symtab_section->data + sym_index;

                /* patch the original symbol */
                sym->st_value = offset;
                sym->st_shndx = text_section->sh_num;
                sym->st_other &= ~1; /* do not export */
                continue;
            }

            if (type == STT_OBJECT) { /* data, ptr to that should be */
                if (0 == is->iat_index) {
                    /* original symbol will be patched later in pe_build_imports */
                    is->iat_index = sym_index;
                    continue;
                }
            }

        not_found:
            error_noabort("undefined symbol '%s'", name);
            ret = 1;

        } else if (pe->s1->rdynamic
                   && ELF32_ST_BIND(sym->st_info) != STB_LOCAL) {
            /* if -rdynamic option, then export all non local symbols */
            sym->st_other |= 1;
        }
    }
    return ret;
}

/*----------------------------------------------------------------------------*/
#ifdef PE_PRINT_SECTIONS
ST_FN void pe_print_section(FILE * f, Section * s)
{
    /* just if you'r curious */
    BYTE *p, *e, b;
    int i, n, l, m;
    p = s->data;
    e = s->data + s->data_offset;
    l = e - p;

    fprintf(f, "section  \"%s\"", s->name);
    if (s->link)
        fprintf(f, "\nlink     \"%s\"", s->link->name);
    if (s->reloc)
        fprintf(f, "\nreloc    \"%s\"", s->reloc->name);
    fprintf(f, "\nv_addr   %08X", s->sh_addr);
    fprintf(f, "\ncontents %08X", l);
    fprintf(f, "\n\n");

    if (s->sh_type == SHT_NOBITS)
        return;

    if (0 == l)
        return;

    if (s->sh_type == SHT_SYMTAB)
        m = sizeof(Elf32_Sym);
    if (s->sh_type == SHT_REL)
        m = sizeof(Elf32_Rel);
    else
        m = 16;

    fprintf(f, "%-8s", "offset");
    for (i = 0; i < m; ++i)
        fprintf(f, " %02x", i);
    n = 56;

    if (s->sh_type == SHT_SYMTAB || s->sh_type == SHT_REL) {
        const char *fields1[] = {
            "name",
            "value",
            "size",
            "bind",
            "type",
            "other",
            "shndx",
            NULL
        };

        const char *fields2[] = {
            "offs",
            "type",
            "symb",
            NULL
        };

        const char **p;

        if (s->sh_type == SHT_SYMTAB)
            p = fields1, n = 106;
        else
            p = fields2, n = 58;

        for (i = 0; p[i]; ++i)
            fprintf(f, "%6s", p[i]);
        fprintf(f, "  symbol");
    }

    fprintf(f, "\n");
    for (i = 0; i < n; ++i)
        fprintf(f, "-");
    fprintf(f, "\n");

    for (i = 0; i < l;)
    {
        fprintf(f, "%08X", i);
        for (n = 0; n < m; ++n) {
            if (n + i < l)
                fprintf(f, " %02X", p[i + n]);
            else
                fprintf(f, "   ");
        }

        if (s->sh_type == SHT_SYMTAB) {
            Elf32_Sym *sym = (Elf32_Sym *) (p + i);
            const char *name = s->link->data + sym->st_name;
            fprintf(f, "  %04X  %04X  %04X   %02X    %02X    %02X   %04X  \"%s\"",
                    sym->st_name,
                    sym->st_value,
                    sym->st_size,
                    ELF32_ST_BIND(sym->st_info),
                    ELF32_ST_TYPE(sym->st_info),
                    sym->st_other, sym->st_shndx, name);

        } else if (s->sh_type == SHT_REL) {
            Elf32_Rel *rel = (Elf32_Rel *) (p + i);
            Elf32_Sym *sym =
                (Elf32_Sym *) s->link->data + ELF32_R_SYM(rel->r_info);
            const char *name = s->link->link->data + sym->st_name;
            fprintf(f, "  %04X   %02X   %04X  \"%s\"",
                    rel->r_offset,
                    ELF32_R_TYPE(rel->r_info),
                    ELF32_R_SYM(rel->r_info), name);
        } else {
            fprintf(f, "   ");
            for (n = 0; n < m; ++n) {
                if (n + i < l) {
                    b = p[i + n];
                    if (b < 32 || b >= 127)
                        b = '.';
                    fprintf(f, "%c", b);
                }
            }
        }
        i += m;
        fprintf(f, "\n");
    }
    fprintf(f, "\n\n");
}

ST_FN void pe_print_sections(TCCState *s1, const char *fname)
{
    Section *s;
    FILE *f;
    int i;
    f = fopen(fname, "wt");
    for (i = 1; i < s1->nb_sections; ++i) {
        s = s1->sections[i];
        pe_print_section(f, s);
    }
    pe_print_section(f, s1->dynsymtab_section);
    fclose(f);
}
#endif

/* -------------------------------------------------------------
 *  This is for compiled windows resources in 'coff' format
 *  as generated by 'windres.exe -O coff ...'.
 */

PUB_FN int pe_test_res_file(void *v, int size)
{
    struct pe_rsrc_header *p = (struct pe_rsrc_header *)v;
    return
        size >= IMAGE_SIZEOF_FILE_HEADER + IMAGE_SIZEOF_SHORT_NAME /* = 28 */
        && p->filehdr.Machine == 0x014C
        && 1 == p->filehdr.NumberOfSections
        && 0 == strcmp(p->sectionhdr.Name, ".rsrc")
        ;
}

ST_FN int read_n(int fd, void *ptr, unsigned size)
{
    return size == read(fd, ptr, size);
}

PUB_FN int pe_load_res_file(TCCState *s1, int fd)
{
    struct pe_rsrc_header hdr;
    Section *rsrc_section;
    int i, ret = -1;
    BYTE *ptr;

    lseek (fd, 0, SEEK_SET);
    if (!read_n(fd, &hdr, sizeof hdr))
        goto quit;
    if (!pe_test_res_file(&hdr, sizeof hdr))
        goto quit;

    rsrc_section = new_section(s1, ".rsrc", SHT_PROGBITS, SHF_ALLOC);
    ptr = section_ptr_add(rsrc_section, hdr.sectionhdr.SizeOfRawData);
    lseek (fd, hdr.sectionhdr.PointerToRawData, SEEK_SET);
    if (!read_n(fd, ptr, hdr.sectionhdr.SizeOfRawData))
        goto quit;

    lseek (fd, hdr.sectionhdr.PointerToRelocations, SEEK_SET);
    for (i = 0; i < hdr.sectionhdr.NumberOfRelocations; ++i)
    {
        struct pe_rsrc_reloc rel;
        if (!read_n(fd, &rel, sizeof rel))
            goto quit;
        // printf("rsrc_reloc: %x %x %x\n", rel.offset, rel.size, rel.type);
        if (rel.type != 7) /* DIR32NB */
            goto quit;
        put_elf_reloc(symtab_section, rsrc_section,
            rel.offset, R_386_RELATIVE, 0);
    }
    ret = 0;
quit:
    if (ret)
        error_noabort("unrecognized resource file format");
    return ret;
}

/* ------------------------------------------------------------- */
ST_FN char *trimfront(char *p)
{
    while (*p && (unsigned char)*p <= ' ')
        ++p;
    return p;
}

ST_FN char *trimback(char *a, char *e)
{
    while (e > a && (unsigned char)e[-1] <= ' ')
        --e;
    *e = 0;;
    return a;
}

ST_FN char *get_line(char *line, int size, FILE *fp)
{
    if (NULL == fgets(line, size, fp))
        return NULL;
    trimback(line, strchr(line, 0));
    return trimfront(line);
}

/* ------------------------------------------------------------- */
PUB_FN int pe_load_def_file(TCCState *s1, int fd)
{
    DLLReference *dllref;
    int state = 0, ret = -1;
    char line[400], dllname[80], *p;
    FILE *fp = fdopen(dup(fd), "rb");

    if (NULL == fp)
        goto quit;

    for (;;) {
        p = get_line(line, sizeof line, fp);
        if (NULL == p)
            break;
        if (0 == *p || ';' == *p)
            continue;
        switch (state) {
        case 0:
            if (0 != strnicmp(p, "LIBRARY", 7))
                goto quit;
            strcpy(dllname, trimfront(p+7));
            ++state;
            continue;

        case 1:
            if (0 != stricmp(p, "EXPORTS"))
                goto quit;
            ++state;
            continue;

        case 2:
            dllref = tcc_mallocz(sizeof(DLLReference) + strlen(dllname));
            strcpy(dllref->name, dllname);
            dynarray_add((void ***) &s1->loaded_dlls, &s1->nb_loaded_dlls, dllref);
            ++state;

        default:
            add_elf_sym(s1->dynsymtab_section,
                s1->nb_loaded_dlls, 0,
                ELF32_ST_INFO(STB_GLOBAL, STT_FUNC), 0,
                text_section->sh_num, p);
            continue;
        }
    }
    ret = 0;
quit:
    if (fp)
        fclose(fp);
    if (ret)
        error_noabort("unrecognized export definition file format");
    return ret;
}

/* ------------------------------------------------------------- */

ST_FN void pe_add_runtime_ex(TCCState *s1, struct pe_info *pe)
{
    const char *start_symbol;
    unsigned long addr = 0;
    int pe_type = 0;

    if (find_elf_sym(symtab_section, "_WinMain@16"))
        pe_type = PE_GUI;
    else
    if (TCC_OUTPUT_DLL == s1->output_type) {
        pe_type = PE_DLL;
        /* need this for 'tccelf.c:relocate_section()' */
        s1->output_type = TCC_OUTPUT_EXE;
    }

    start_symbol =
        TCC_OUTPUT_MEMORY == s1->output_type
        ? PE_GUI == pe_type ? "_runwinmain" : NULL
        : PE_DLL == pe_type ? "__dllstart@12"
        : PE_GUI == pe_type ? "_winstart" : "_start"
        ;

    /* grab the startup code from libtcc1 */
    if (start_symbol)
        add_elf_sym(symtab_section,
            0, 0,
            ELF32_ST_INFO(STB_GLOBAL, STT_NOTYPE), 0,
            SHN_UNDEF, start_symbol);

    if (0 == s1->nostdlib) {
        tcc_add_library(s1, "tcc1");
#ifdef __CYGWIN__
        tcc_add_library(s1, "cygwin1");
#else
        tcc_add_library(s1, "msvcrt");
#endif
        tcc_add_library(s1, "kernel32");
        if (PE_DLL == pe_type || PE_GUI == pe_type) {
            tcc_add_library(s1, "user32");
            tcc_add_library(s1, "gdi32");
        }
    }

    if (start_symbol) {
        addr = (unsigned long)tcc_get_symbol_err(s1, start_symbol);
        if (s1->output_type == TCC_OUTPUT_MEMORY && addr)
            /* for -run GUI's, put '_runwinmain' instead of 'main' */
            add_elf_sym(symtab_section,
                    addr, 0,
                    ELF32_ST_INFO(STB_GLOBAL, STT_NOTYPE), 0,
                    text_section->sh_num, "main");
    }

    if (pe) {
        pe->type = pe_type;
        pe->start_addr = addr;
    }
}

PUB_FN void pe_add_runtime(TCCState *s1)
{
    pe_add_runtime_ex(s1, NULL);
}

PUB_FN int pe_output_file(TCCState * s1, const char *filename)
{
    int ret;
    struct pe_info pe;
    int i;

    memset(&pe, 0, sizeof pe);
    pe.filename = filename;
    pe.s1 = s1;

    pe_add_runtime_ex(s1, &pe);
    relocate_common_syms(); /* assign bss adresses */
    tcc_add_linker_symbols(s1);

    ret = pe_check_symbols(&pe);
    if (0 == ret) {
        if (PE_DLL == pe.type) {
            pe.reloc = new_section(pe.s1, ".reloc", SHT_PROGBITS, 0);
            pe.imagebase = 0x10000000;
        } else {
            pe.imagebase = 0x00400000;
        }
        pe_assign_addresses(&pe);
        relocate_syms(s1, 0);
        for (i = 1; i < s1->nb_sections; ++i) {
            Section *s = s1->sections[i];
            if (s->reloc) {
                relocate_section(s1, s);
                pe_relocate_rva(&pe, s);
            }
        }
        if (s1->nb_errors)
            ret = 1;
        else
            ret = pe_write(&pe);
        tcc_free(pe.sec_info);
    }

#ifdef PE_PRINT_SECTIONS
    pe_print_sections(s1, "tcc.log");
#endif
    return ret;
}

/* ------------------------------------------------------------- */
#endif /* def TCC_TARGET_PE */
/* ------------------------------------------------------------- */
