/*
 * This program is for making libtcc1.a without ar
 * tiny_libmaker - tiny elf lib maker
 * usage: tiny_libmaker [lib] files...
 * Copyright (c) 2007 Timppa
 *
 * This program is free software but WITHOUT ANY WARRANTY
 */ 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <io.h> /* for mktemp */
#endif

/* #include "ar-elf.h" */
/*  "ar-elf.h" */
/* ELF_v1.2.pdf */
typedef unsigned short int Elf32_Half;
typedef int Elf32_Sword;
typedef unsigned int Elf32_Word;
typedef unsigned int Elf32_Addr;
typedef unsigned int Elf32_Off;
typedef unsigned short int Elf32_Section;

#define EI_NIDENT 16
typedef struct {
    unsigned char e_ident[EI_NIDENT];
    Elf32_Half e_type;
    Elf32_Half e_machine;
    Elf32_Word e_version;
    Elf32_Addr e_entry;
    Elf32_Off e_phoff;
    Elf32_Off e_shoff;
    Elf32_Word e_flags;
    Elf32_Half e_ehsize;
    Elf32_Half e_phentsize;
    Elf32_Half e_phnum;
    Elf32_Half e_shentsize;
    Elf32_Half e_shnum;
    Elf32_Half e_shstrndx;
} Elf32_Ehdr;

typedef struct {
    Elf32_Word sh_name;
    Elf32_Word sh_type;
    Elf32_Word sh_flags;
    Elf32_Addr sh_addr;
    Elf32_Off sh_offset;
    Elf32_Word sh_size;
    Elf32_Word sh_link;
    Elf32_Word sh_info;
    Elf32_Word sh_addralign;
    Elf32_Word sh_entsize;
} Elf32_Shdr;

#define SHT_NULL 0
#define SHT_PROGBITS 1
#define SHT_SYMTAB 2
#define SHT_STRTAB 3
#define SHT_RELA 4
#define SHT_HASH 5
#define SHT_DYNAMIC 6
#define SHT_NOTE 7
#define SHT_NOBITS 8
#define SHT_REL 9
#define SHT_SHLIB 10
#define SHT_DYNSYM 11

typedef struct {
    Elf32_Word st_name;
    Elf32_Addr st_value;
    Elf32_Word st_size;
    unsigned char st_info;
    unsigned char st_other;
    Elf32_Half st_shndx;
} Elf32_Sym;

#define ELF32_ST_BIND(i) ((i)>>4)
#define ELF32_ST_TYPE(i) ((i)&0xf)
#define ELF32_ST_INFO(b,t) (((b)<<4)+((t)&0xf))

#define STT_NOTYPE 0
#define STT_OBJECT 1
#define STT_FUNC 2
#define STT_SECTION 3
#define STT_FILE 4
#define STT_LOPROC 13
#define STT_HIPROC 15

#define STB_LOCAL 0
#define STB_GLOBAL 1
#define STB_WEAK 2
#define STB_LOPROC 13
#define STB_HIPROC 15

typedef struct {
    Elf32_Word p_type;
    Elf32_Off p_offset;
    Elf32_Addr p_vaddr;
    Elf32_Addr p_paddr;
    Elf32_Word p_filesz;
    Elf32_Word p_memsz;
    Elf32_Word p_flags;
    Elf32_Word p_align;
} Elf32_Phdr;
/* "ar-elf.h" ends */

#define ARMAG  "!<arch>\n"
#define ARFMAG "`\n"

typedef struct ArHdr {
    char ar_name[16];
    char ar_date[12];
    char ar_uid[6];
    char ar_gid[6];
    char ar_mode[8];
    char ar_size[10];
    char ar_fmag[2];
} ArHdr;


unsigned long le2belong(unsigned long ul) {
    return ((ul & 0xFF0000)>>8)+((ul & 0xFF000000)>>24) +
        ((ul & 0xFF)<<24)+((ul & 0xFF00)<<8);
}

ArHdr arhdr = {
    "/               ",
    "            ",
    "0     ",
    "0     ",
    "0       ",
    "          ",
    ARFMAG
    };

ArHdr arhdro = {
    "                ",
    "            ",
    "0     ",
    "0     ",
    "0       ",
    "          ",
    ARFMAG
    };

int main(int argc, char **argv)
{
    FILE *fi, *fh, *fo;
    Elf32_Ehdr *ehdr;
    Elf32_Shdr *shdr;
    Elf32_Sym *sym;
    int i, fsize, iarg;
    char *buf, *shstr, *symtab = NULL, *strtab = NULL;
    int symtabsize = 0, strtabsize = 0;
    char *anames = NULL;
    int *afpos = NULL;
    int istrlen, strpos = 0, fpos = 0, funccnt = 0, funcmax, hofs;
    char afile[260], tfile[260], stmp[20];


    strcpy(afile, "ar_test.a");
    iarg = 1;

    if (argc < 2)
    {
        printf("usage: tiny_libmaker [lib] file...\n");
        return 1;
    }
    for (i=1; i<argc; i++) {
        istrlen = strlen(argv[i]);
        if (argv[i][istrlen-2] == '.') {
            if(argv[i][istrlen-1] == 'a')
                strcpy(afile, argv[i]);
            else if(argv[i][istrlen-1] == 'o') {
                iarg = i;
                break;
            }
        }
    }

    strcpy(tfile, "./XXXXXX");
    if (!mktemp(tfile) || (fo = fopen(tfile, "wb+")) == NULL)
    {
        fprintf(stderr, "Can't open temporary file %s\n", tfile);
        return 2;
    }

    if ((fh = fopen(afile, "wb")) == NULL)
    {
        fprintf(stderr, "Can't open file %s \n", afile);
        remove(tfile);
        return 2;
    }

    funcmax = 250;
    afpos = realloc(NULL, funcmax * sizeof *afpos); // 250 func
    memcpy(&arhdro.ar_mode, "100666", 6);

    //iarg = 1;
    while (iarg < argc)
    {
        if (!strcmp(argv[iarg], "rcs")) {
            iarg++;
            continue;
        }
        if ((fi = fopen(argv[iarg], "rb")) == NULL)
        {
            fprintf(stderr, "Can't open  file %s \n", argv[iarg]);
            remove(tfile);
            return 2;
        }
        fseek(fi, 0, SEEK_END);
        fsize = ftell(fi);
        fseek(fi, 0, SEEK_SET);
        buf = malloc(fsize + 1);
        fread(buf, fsize, 1, fi);
        fclose(fi);

        printf("%s:\n", argv[iarg]);
        // elf header
        ehdr = (Elf32_Ehdr *)buf;
        shdr = (Elf32_Shdr *) (buf + ehdr->e_shoff + ehdr->e_shstrndx * ehdr->e_shentsize);
        shstr = (char *)(buf + shdr->sh_offset);
        for (i = 0; i < ehdr->e_shnum; i++)
        {
            shdr = (Elf32_Shdr *) (buf + ehdr->e_shoff + i * ehdr->e_shentsize);
            if (!shdr->sh_offset) continue;
            if (shdr->sh_type == SHT_SYMTAB)
            {
                symtab = (char *)(buf + shdr->sh_offset);
                symtabsize = shdr->sh_size;
            }
            if (shdr->sh_type == SHT_STRTAB)
            {
                if (!strcmp(shstr + shdr->sh_name, ".strtab"))
                {
                    strtab = (char *)(buf + shdr->sh_offset);
                    strtabsize = shdr->sh_size;
                }
            }
        }

        if (symtab && symtabsize)
        {
            int nsym = symtabsize / sizeof(Elf32_Sym);
            //printf("symtab: info size shndx name\n");
            for (i = 1; i < nsym; i++)
            {
                sym = (Elf32_Sym *) (symtab + i * sizeof(Elf32_Sym));
                if (sym->st_shndx && (sym->st_info == 0x11 || sym->st_info == 0x12)) {
                    //printf("symtab: %2Xh %4Xh %2Xh %s\n", sym->st_info, sym->st_size, sym->st_shndx, strtab + sym->st_name);
                    istrlen = strlen(strtab + sym->st_name)+1;
                    anames = realloc(anames, strpos+istrlen);
                    strcpy(anames + strpos, strtab + sym->st_name);
                    strpos += istrlen;
                    if (++funccnt >= funcmax) {
                        funcmax += 250;
                        afpos = realloc(afpos, funcmax * sizeof *afpos); // 250 func more
                    }
                    afpos[funccnt] = fpos;
                }
            }
        }
        memset(&arhdro.ar_name, ' ', sizeof(arhdr.ar_name));
        strcpy(arhdro.ar_name, argv[iarg]);
        arhdro.ar_name[strlen(argv[iarg])] = '/';
        sprintf(stmp, "%-10d", fsize);
        memcpy(&arhdro.ar_size, stmp, 10);
        fwrite(&arhdro, sizeof(arhdro), 1, fo);
        fwrite(buf, fsize, 1, fo);
        free(buf);
        iarg++;
        fpos += (fsize + sizeof(arhdro));
    }
    hofs = 8 + sizeof(arhdr) + strpos + (funccnt+1) * sizeof(int);
    if ((hofs & 1)) {   // align
        hofs++;
        fpos = 1;
    } else fpos = 0;
    // write header
    fwrite("!<arch>\n", 8, 1, fh);
    sprintf(stmp, "%-10d", strpos + (funccnt+1) * sizeof(int));
    memcpy(&arhdr.ar_size, stmp, 10);
    fwrite(&arhdr, sizeof(arhdr), 1, fh);
    afpos[0] = le2belong(funccnt);
    for (i=1; i<=funccnt; i++) {
        afpos[i] = le2belong(afpos[i] + hofs);
    }
    fwrite(afpos, (funccnt+1) * sizeof(int), 1, fh);
    fwrite(anames, strpos, 1, fh);
    if (fpos) fwrite("", 1, 1, fh);
    // write objects
    fseek(fo, 0, SEEK_END);
    fsize = ftell(fo);
    fseek(fo, 0, SEEK_SET);
    buf = malloc(fsize + 1);
    fread(buf, fsize, 1, fo);
    fclose(fo);
    fwrite(buf, fsize, 1, fh);
    fclose(fh);
    free(buf);
    if (anames)
        free(anames);
    if (afpos)
        free(afpos);
    remove(tfile);
    return 0;
}
