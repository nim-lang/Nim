/* -------------------------------------------------------------- */
/*
 * tiny_impdef creates an export definition file (.def) from a dll
 * on MS-Windows. Usage: tiny_impdef library.dll [-o outputfile]"
 * 
 *  Copyright (c) 2005,2007 grischka
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>

/* Offset to PE file signature */
#define NTSIGNATURE(a) ((LPVOID)((BYTE *)a                +  \
                        ((PIMAGE_DOS_HEADER)a)->e_lfanew))

/* MS-OS header identifies the NT PEFile signature dword;
   the PEFILE header exists just after that dword. */
#define PEFHDROFFSET(a) ((LPVOID)((BYTE *)a               +  \
                         ((PIMAGE_DOS_HEADER)a)->e_lfanew +  \
                             SIZE_OF_NT_SIGNATURE))

/* PE optional header is immediately after PEFile header. */
#define OPTHDROFFSET(a) ((LPVOID)((BYTE *)a               +  \
                         ((PIMAGE_DOS_HEADER)a)->e_lfanew +  \
                           SIZE_OF_NT_SIGNATURE           +  \
                           sizeof (IMAGE_FILE_HEADER)))

/* Section headers are immediately after PE optional header. */
#define SECHDROFFSET(a) ((LPVOID)((BYTE *)a               +  \
                         ((PIMAGE_DOS_HEADER)a)->e_lfanew +  \
                           SIZE_OF_NT_SIGNATURE           +  \
                           sizeof (IMAGE_FILE_HEADER)     +  \
                           sizeof (IMAGE_OPTIONAL_HEADER)))


#define SIZE_OF_NT_SIGNATURE 4

/* -------------------------------------------------------------- */

int WINAPI NumOfSections (
    LPVOID lpFile)
{
    /* Number of sections is indicated in file header. */
    return (int)
        ((PIMAGE_FILE_HEADER)
            PEFHDROFFSET(lpFile))->NumberOfSections;
}


/* -------------------------------------------------------------- */

LPVOID WINAPI ImageDirectoryOffset (
    LPVOID lpFile,
    DWORD dwIMAGE_DIRECTORY)
{
    PIMAGE_OPTIONAL_HEADER poh;
    PIMAGE_SECTION_HEADER psh;
    int nSections = NumOfSections (lpFile);
    int i = 0;
    LPVOID VAImageDir;

    /* Retrieve offsets to optional and section headers. */
    poh = (PIMAGE_OPTIONAL_HEADER)OPTHDROFFSET (lpFile);
    psh = (PIMAGE_SECTION_HEADER)SECHDROFFSET (lpFile);

    /* Must be 0 thru (NumberOfRvaAndSizes-1). */
    if (dwIMAGE_DIRECTORY >= poh->NumberOfRvaAndSizes)
        return NULL;

    /* Locate image directory's relative virtual address. */
    VAImageDir = (LPVOID)poh->DataDirectory[dwIMAGE_DIRECTORY].VirtualAddress;

    /* Locate section containing image directory. */
    while (i++<nSections)
    {
        if (psh->VirtualAddress <= (DWORD)VAImageDir
         && psh->VirtualAddress + psh->SizeOfRawData > (DWORD)VAImageDir)
            break;
        psh++;
    }

    if (i > nSections)
        return NULL;

    /* Return image import directory offset. */
    return (LPVOID)(((int)lpFile +
                     (int)VAImageDir - psh->VirtualAddress) +
                    (int)psh->PointerToRawData);
}

/* -------------------------------------------------------------- */

BOOL WINAPI GetSectionHdrByName (
    LPVOID lpFile,
    IMAGE_SECTION_HEADER *sh,
    char *szSection)
{
    PIMAGE_SECTION_HEADER psh;
    int nSections = NumOfSections (lpFile);
    int i;

    if ((psh = (PIMAGE_SECTION_HEADER)SECHDROFFSET (lpFile)) != NULL)
    {
        /* find the section by name */
        for (i=0; i<nSections; i++)
        {
            if (!strcmp (psh->Name, szSection))
            {
                /* copy data to header */
                memcpy ((LPVOID)sh, (LPVOID)psh, sizeof (IMAGE_SECTION_HEADER));
                return TRUE;
            }
            else
                psh++;
        }
    }
    return FALSE;
}

/* -------------------------------------------------------------- */

BOOL WINAPI GetSectionHdrByAddress (
    LPVOID lpFile,
    IMAGE_SECTION_HEADER *sh,
    DWORD addr)
{
    PIMAGE_SECTION_HEADER psh;
    int nSections = NumOfSections (lpFile);
    int i;

    if ((psh = (PIMAGE_SECTION_HEADER)SECHDROFFSET (lpFile)) != NULL)
    {
        /* find the section by name */
        for (i=0; i<nSections; i++)
        {
            if (addr >= psh->VirtualAddress
             && addr < psh->VirtualAddress + psh->SizeOfRawData)
            {
                /* copy data to header */
                memcpy ((LPVOID)sh, (LPVOID)psh, sizeof (IMAGE_SECTION_HEADER));
                return TRUE;
            }
            else
                psh++;
        }
    }
    return FALSE;
}

/* -------------------------------------------------------------- */

int  WINAPI GetExportFunctionNames (
    LPVOID lpFile,
    HANDLE hHeap,
    char **pszFunctions)
{
    IMAGE_SECTION_HEADER sh;
    PIMAGE_EXPORT_DIRECTORY ped;
    int *pNames, *pCnt;
    char *pSrc, *pDest;
    int i, nCnt;
    DWORD VAImageDir;
    PIMAGE_OPTIONAL_HEADER poh;
    char *pOffset;

    /* Get section header and pointer to data directory
       for .edata section. */
    if (NULL == (ped = (PIMAGE_EXPORT_DIRECTORY)
        ImageDirectoryOffset (lpFile, IMAGE_DIRECTORY_ENTRY_EXPORT)))
        return 0;

    poh = (PIMAGE_OPTIONAL_HEADER)OPTHDROFFSET (lpFile);
    VAImageDir = poh->DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;

    if (FALSE == GetSectionHdrByAddress (lpFile, &sh, VAImageDir))
        return 0;

    pOffset = (char *)lpFile + (sh.PointerToRawData -  sh.VirtualAddress);

    pNames = (int *)(pOffset + (DWORD)ped->AddressOfNames);

    /* Figure out how much memory to allocate for all strings. */
    nCnt = 1;
    for (i=0, pCnt = pNames; i<(int)ped->NumberOfNames; i++)
    {
        pSrc = (pOffset + *pCnt++);
        if (pSrc)
            nCnt += strlen(pSrc)+1;
    }

    /* Allocate memory off heap for function names. */
    pDest = *pszFunctions = HeapAlloc (hHeap, HEAP_ZERO_MEMORY, nCnt);

    /* Copy all strings to buffer. */
    for (i=0, pCnt = pNames; i<(int)ped->NumberOfNames; i++)
    {
        pSrc = (pOffset + *pCnt++);
        if (pSrc) {
            strcpy(pDest, pSrc);
            pDest += strlen(pSrc)+1;
        }
    }
    *pDest = 0;

    return ped->NumberOfNames;
}

/* -------------------------------------------------------------- */
/* extract the basename of a file */

static char *file_basename(const char *name)
{
    const char *p = strchr(name, 0);
    while (p > name
        && p[-1] != '/'
        && p[-1] != '\\'
        )
        --p;
    return (char*)p;
}

/* -------------------------------------------------------------- */

int main(int argc, char **argv)
{
    HANDLE hHeap;
    HANDLE hFile;
    HANDLE hMapObject;
    VOID *pMem;

    int nCnt, ret, n;
    char *pNames;
    char infile[MAX_PATH];
    char buffer[MAX_PATH];
    char outfile[MAX_PATH];
    FILE *op;
    char *p;

    hHeap = NULL;
    hFile = NULL;
    hMapObject = NULL;
    pMem = NULL;
    infile[0] = 0;
    outfile[0] = 0;
    ret = 1;

    for (n = 1; n < argc; ++n)
    {
        const char *a = argv[n];
        if ('-' == a[0]) {
            if (0 == strcmp(a, "-o")) {
                if (++n == argc)
                    goto usage;
                strcpy(outfile, argv[n]);
            }
            else
                goto usage;

        } else if (0 == infile[0])
            strcpy(infile, a);
        else
            goto usage;
    }

    if (0 == infile[0])
    {
usage:
        fprintf(stderr,
            "tiny_impdef creates an export definition file (.def) from a dll\n"
            "Usage: tiny_impdef library.dll [-o outputfile]\n"
            );
        goto the_end;
    }

    if (SearchPath(NULL, infile, ".dll", sizeof buffer, buffer, NULL))
        strcpy(infile, buffer);

    if (0 == outfile[0])
    {
        char *p;
        strcpy(outfile, file_basename(infile));
        p = strrchr(outfile, '.');
        if (NULL == p)
            p = strchr(outfile, 0);
        strcpy(p, ".def");
    }

    hFile = CreateFile(
        infile,
        GENERIC_READ,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
        );

    if (hFile == INVALID_HANDLE_VALUE)
    {
        fprintf(stderr, "No such file: %s\n", infile);
        goto the_end;
    }


    hMapObject = CreateFileMapping(
        hFile,
        NULL,
        PAGE_READONLY,
        0, 0,
        NULL
        );

    if (NULL == hMapObject)
    {
        fprintf(stderr, "Could not create file mapping: %s\n", infile);
        goto the_end;
    }

    pMem = MapViewOfFile(
        hMapObject,     // object to map view of
        FILE_MAP_READ,  // read access
        0,              // high offset:  map from
        0,              // low offset:   beginning
        0);             // default: map entire file

    if (NULL == pMem)
    {
        fprintf(stderr, "Could not map view of file: %s\n", infile);
        goto the_end;
    }

    if (0 != strncmp(NTSIGNATURE(pMem), "PE", 2))
    {
        fprintf(stderr, "Not a PE file: %s\n", infile);
        goto the_end;
    }


    hHeap = GetProcessHeap();
    nCnt = GetExportFunctionNames(pMem, hHeap, &pNames);
    if (0 == nCnt) {
        fprintf(stderr, "Could not get exported function names: %s\n", infile);
        goto the_end;
    }

    printf("--> %s\n", infile);

    op = fopen(outfile, "w");
    if (NULL == op)
    {
        fprintf(stderr, "Could not create file: %s\n", outfile);
        goto the_end;
    }

    printf("<-- %s\n", outfile);

    fprintf(op, "LIBRARY %s\n\nEXPORTS\n", file_basename(infile));
    for (n = 0, p = pNames; n < nCnt; ++n)
    {
        fprintf(op, "%s\n", p);
        while (*p++);
    }
    ret = 0;

the_end:
    if (pMem)
        UnmapViewOfFile(pMem);

    if (hMapObject)
        CloseHandle(hMapObject);

    if (hFile)
        CloseHandle(hFile);

    return ret;
}

/* -------------------------------------------------------------- */
