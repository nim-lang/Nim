/*
 *  TCC - Tiny C Compiler
 * 
 *  Copyright (c) 2001-2004 Fabrice Bellard
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

#define _GNU_SOURCE
#include "config.h"

#ifdef CONFIG_TCCBOOT

#include "tccboot.h"
#define CONFIG_TCC_STATIC

#else

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <signal.h>
#include <fcntl.h>
#include <setjmp.h>
#include <time.h>

#ifdef _WIN32
#include <windows.h>
#include <sys/timeb.h>
#include <io.h> /* open, close etc. */
#include <direct.h> /* getcwd */
#define inline __inline
#define inp next_inp
#endif

#ifndef _WIN32
#include <unistd.h>
#include <sys/time.h>
#include <sys/ucontext.h>
#include <sys/mman.h>
#endif

#endif /* !CONFIG_TCCBOOT */

#ifndef PAGESIZE
#define PAGESIZE 4096
#endif

#include "elf.h"
#include "stab.h"

#ifndef O_BINARY
#define O_BINARY 0
#endif

#include "libtcc.h"

/* parser debug */
//#define PARSE_DEBUG
/* preprocessor debug */
//#define PP_DEBUG
/* include file debug */
//#define INC_DEBUG

//#define MEM_DEBUG

/* assembler debug */
//#define ASM_DEBUG

/* target selection */
//#define TCC_TARGET_I386   /* i386 code generator */
//#define TCC_TARGET_ARM    /* ARMv4 code generator */
//#define TCC_TARGET_C67    /* TMS320C67xx code generator */
//#define TCC_TARGET_X86_64 /* x86-64 code generator */

/* default target is I386 */
#if !defined(TCC_TARGET_I386) && !defined(TCC_TARGET_ARM) && \
    !defined(TCC_TARGET_C67) && !defined(TCC_TARGET_X86_64)
#define TCC_TARGET_I386
#endif

#if !defined(_WIN32) && !defined(TCC_UCLIBC) && !defined(TCC_TARGET_ARM) && \
    !defined(TCC_TARGET_C67) && !defined(TCC_TARGET_X86_64)
#define CONFIG_TCC_BCHECK /* enable bound checking code */
#endif

#if defined(_WIN32) && !defined(TCC_TARGET_PE)
#define CONFIG_TCC_STATIC
#endif

/* define it to include assembler support */
#if !defined(TCC_TARGET_ARM) && !defined(TCC_TARGET_C67) && \
    !defined(TCC_TARGET_X86_64)
#define CONFIG_TCC_ASM
#endif

/* object format selection */
#if defined(TCC_TARGET_C67)
#define TCC_TARGET_COFF
#endif

#if !defined(_WIN32) && !defined(CONFIG_TCCBOOT)
#define CONFIG_TCC_BACKTRACE
#endif

#define FALSE 0
#define false 0
#define TRUE 1
#define true 1
typedef int BOOL;

/* path to find crt1.o, crti.o and crtn.o. Only needed when generating
   executables or dlls */
#define CONFIG_TCC_CRT_PREFIX CONFIG_SYSROOT "/usr/lib"

#define INCLUDE_STACK_SIZE  32
#define IFDEF_STACK_SIZE    64
#define VSTACK_SIZE         256
#define STRING_MAX_SIZE     1024
#define PACK_STACK_SIZE     8

#define TOK_HASH_SIZE       8192 /* must be a power of two */
#define TOK_ALLOC_INCR      512  /* must be a power of two */
#define TOK_MAX_SIZE        4 /* token max size in int unit when stored in string */

/* token symbol management */
typedef struct TokenSym {
    struct TokenSym *hash_next;
    struct Sym *sym_define; /* direct pointer to define */
    struct Sym *sym_label; /* direct pointer to label */
    struct Sym *sym_struct; /* direct pointer to structure */
    struct Sym *sym_identifier; /* direct pointer to identifier */
    int tok; /* token number */
    int len;
    char str[1];
} TokenSym;

#ifdef TCC_TARGET_PE
typedef unsigned short nwchar_t;
#else
typedef int nwchar_t;
#endif

typedef struct CString {
    int size; /* size in bytes */
    void *data; /* either 'char *' or 'nwchar_t *' */
    int size_allocated;
    void *data_allocated; /* if non NULL, data has been malloced */
} CString;

/* type definition */
typedef struct CType {
    int t;
    struct Sym *ref;
} CType;

/* constant value */
typedef union CValue {
    long double ld;
    double d;
    float f;
    int i;
    unsigned int ui;
    unsigned int ul; /* address (should be unsigned long on 64 bit cpu) */
    long long ll;
    unsigned long long ull;
    struct CString *cstr;
    void *ptr;
    int tab[1];
} CValue;

/* value on stack */
typedef struct SValue {
    CType type;      /* type */
    unsigned short r;      /* register + flags */
    unsigned short r2;     /* second register, used for 'long long'
                              type. If not used, set to VT_CONST */
    CValue c;              /* constant, if VT_CONST */
    struct Sym *sym;       /* symbol, if (VT_SYM | VT_CONST) */
} SValue;

/* symbol management */
typedef struct Sym {
    int v;    /* symbol token */
    long r;    /* associated register */
    long c;    /* associated number */
    CType type;    /* associated type */
    struct Sym *next; /* next related symbol */
    struct Sym *prev; /* prev symbol in stack */
    struct Sym *prev_tok; /* previous symbol for this token */
} Sym;

/* section definition */
/* XXX: use directly ELF structure for parameters ? */
/* special flag to indicate that the section should not be linked to
   the other ones */
#define SHF_PRIVATE 0x80000000

/* special flag, too */
#define SECTION_ABS ((void *)1)

typedef struct Section {
    unsigned long data_offset; /* current data offset */
    unsigned char *data;       /* section data */
    unsigned long data_allocated; /* used for realloc() handling */
    int sh_name;             /* elf section name (only used during output) */
    int sh_num;              /* elf section number */
    int sh_type;             /* elf section type */
    int sh_flags;            /* elf section flags */
    int sh_info;             /* elf section info */
    int sh_addralign;        /* elf section alignment */
    int sh_entsize;          /* elf entry size */
    unsigned long sh_size;   /* section size (only used during output) */
    unsigned long sh_addr;      /* address at which the section is relocated */
    unsigned long sh_offset;    /* file offset */
    int nb_hashed_syms;      /* used to resize the hash table */
    struct Section *link;    /* link to another section */
    struct Section *reloc;   /* corresponding section for relocation, if any */
    struct Section *hash;     /* hash table for symbols */
    struct Section *next;
    char name[1];           /* section name */
} Section;

typedef struct DLLReference {
    int level;
    void *handle;
    char name[1];
} DLLReference;

/* GNUC attribute definition */
typedef struct AttributeDef {
    int aligned;
    int packed; 
    Section *section;
    int func_attr; /* calling convention, exports, ... */
} AttributeDef;

/* -------------------------------------------------- */
/* gr: wrappers for casting sym->r for other purposes */
typedef struct {
    unsigned
      func_call : 8,
      func_args : 8,
      func_export : 1;
} func_attr_t;

#define FUNC_CALL(r) (((func_attr_t*)&(r))->func_call)
#define FUNC_EXPORT(r) (((func_attr_t*)&(r))->func_export)
#define FUNC_ARGS(r) (((func_attr_t*)&(r))->func_args)
#define INLINE_DEF(r) (*(int **)&(r))
/* -------------------------------------------------- */

#define SYM_STRUCT     0x40000000 /* struct/union/enum symbol space */
#define SYM_FIELD      0x20000000 /* struct/union field symbol space */
#define SYM_FIRST_ANOM 0x10000000 /* first anonymous sym */

/* stored in 'Sym.c' field */
#define FUNC_NEW       1 /* ansi function prototype */
#define FUNC_OLD       2 /* old function prototype */
#define FUNC_ELLIPSIS  3 /* ansi function prototype with ... */

/* stored in 'Sym.r' field */
#define FUNC_CDECL     0 /* standard c call */
#define FUNC_STDCALL   1 /* pascal c call */
#define FUNC_FASTCALL1 2 /* first param in %eax */
#define FUNC_FASTCALL2 3 /* first parameters in %eax, %edx */
#define FUNC_FASTCALL3 4 /* first parameter in %eax, %edx, %ecx */
#define FUNC_FASTCALLW 5 /* first parameter in %ecx, %edx */

/* field 'Sym.t' for macros */
#define MACRO_OBJ      0 /* object like macro */
#define MACRO_FUNC     1 /* function like macro */

/* field 'Sym.r' for C labels */
#define LABEL_DEFINED  0 /* label is defined */
#define LABEL_FORWARD  1 /* label is forward defined */
#define LABEL_DECLARED 2 /* label is declared but never used */

/* type_decl() types */
#define TYPE_ABSTRACT  1 /* type without variable */
#define TYPE_DIRECT    2 /* type with variable */

#define IO_BUF_SIZE 8192

typedef struct BufferedFile {
    uint8_t *buf_ptr;
    uint8_t *buf_end;
    int fd;
    int line_num;    /* current line number - here to simplify code */
    int ifndef_macro;  /* #ifndef macro / #endif search */
    int ifndef_macro_saved; /* saved ifndef_macro */
    int *ifdef_stack_ptr; /* ifdef_stack value at the start of the file */
    char inc_type;          /* type of include */
    char inc_filename[512]; /* filename specified by the user */
    char filename[1024];    /* current filename - here to simplify code */
    unsigned char buffer[IO_BUF_SIZE + 1]; /* extra size for CH_EOB char */
} BufferedFile;

#define CH_EOB   '\\'       /* end of buffer or '\0' char in file */
#define CH_EOF   (-1)   /* end of file */

/* parsing state (used to save parser state to reparse part of the
   source several times) */
typedef struct ParseState {
    int *macro_ptr;
    int line_num;
    int tok;
    CValue tokc;
} ParseState;

/* used to record tokens */
typedef struct TokenString {
    int *str;
    int len;
    int allocated_len;
    int last_line_num;
} TokenString;

/* include file cache, used to find files faster and also to eliminate
   inclusion if the include file is protected by #ifndef ... #endif */
typedef struct CachedInclude {
    int ifndef_macro;
    int hash_next; /* -1 if none */
    char type; /* '"' or '>' to give include type */
    char filename[1]; /* path specified in #include */
} CachedInclude;

#define CACHED_INCLUDES_HASH_SIZE 512

#ifdef CONFIG_TCC_ASM
typedef struct ExprValue {
    uint32_t v;
    Sym *sym;
} ExprValue;

#define MAX_ASM_OPERANDS 30
typedef struct ASMOperand {
    int id; /* GCC 3 optionnal identifier (0 if number only supported */
    char *constraint;
    char asm_str[16]; /* computed asm string for operand */
    SValue *vt; /* C value of the expression */
    int ref_index; /* if >= 0, gives reference to a output constraint */
    int input_index; /* if >= 0, gives reference to an input constraint */
    int priority; /* priority, used to assign registers */
    int reg; /* if >= 0, register number used for this operand */
    int is_llong; /* true if double register value */
    int is_memory; /* true if memory operand */
    int is_rw;     /* for '+' modifier */
} ASMOperand;

#endif

struct TCCState {
    int output_type;
 
    BufferedFile **include_stack_ptr;
    int *ifdef_stack_ptr;

    /* include file handling */
    char **include_paths;
    int nb_include_paths;
    char **sysinclude_paths;
    int nb_sysinclude_paths;
    CachedInclude **cached_includes;
    int nb_cached_includes;

    char **library_paths;
    int nb_library_paths;

    /* array of all loaded dlls (including those referenced by loaded
       dlls) */
    DLLReference **loaded_dlls;
    int nb_loaded_dlls;

    /* sections */
    Section **sections;
    int nb_sections; /* number of sections, including first dummy section */

    Section **priv_sections;
    int nb_priv_sections; /* number of private sections */

    /* got handling */
    Section *got;
    Section *plt;
    unsigned long *got_offsets;
    int nb_got_offsets;
    /* give the correspondance from symtab indexes to dynsym indexes */
    int *symtab_to_dynsym;

    /* temporary dynamic symbol sections (for dll loading) */
    Section *dynsymtab_section;
    /* exported dynamic symbol section */
    Section *dynsym;

    int nostdinc; /* if true, no standard headers are added */
    int nostdlib; /* if true, no standard libraries are added */
    int nocommon; /* if true, do not use common symbols for .bss data */

    /* if true, static linking is performed */
    int static_link;

    /* soname as specified on the command line (-soname) */
    const char *soname;

    /* if true, all symbols are exported */
    int rdynamic;

    /* if true, only link in referenced objects from archive */
    int alacarte_link;

    /* address of text section */
    unsigned long text_addr;
    int has_text_addr;
    
    /* output format, see TCC_OUTPUT_FORMAT_xxx */
    int output_format;

    /* C language options */
    int char_is_unsigned;
    int leading_underscore;
    
    /* warning switches */
    int warn_write_strings;
    int warn_unsupported;
    int warn_error;
    int warn_none;
    int warn_implicit_function_declaration;

    /* display some information during compilation */
    int verbose;
    /* compile with debug symbol (and use them if error during execution) */
    int do_debug;
    /* compile with built-in memory and bounds checker */
    int do_bounds_check;
    /* give the path of the tcc libraries */
    const char *tcc_lib_path;

    /* error handling */
    void *error_opaque;
    void (*error_func)(void *opaque, const char *msg);
    int error_set_jmp_enabled;
    jmp_buf error_jmp_buf;
    int nb_errors;

    /* tiny assembler state */
    Sym *asm_labels;

    /* see include_stack_ptr */
    BufferedFile *include_stack[INCLUDE_STACK_SIZE];

    /* see ifdef_stack_ptr */
    int ifdef_stack[IFDEF_STACK_SIZE];

    /* see cached_includes */
    int cached_includes_hash[CACHED_INCLUDES_HASH_SIZE];

    /* pack stack */
    int pack_stack[PACK_STACK_SIZE];
    int *pack_stack_ptr;

    /* output file for preprocessing */
    FILE *outfile;

    /* for tcc_relocate */
    int runtime_added;

#ifdef TCC_TARGET_X86_64
    /* write PLT and GOT here */
    char *runtime_plt_and_got;
    unsigned int runtime_plt_and_got_offset;
#endif
};

/* The current value can be: */
#define VT_VALMASK   0x00ff
#define VT_CONST     0x00f0  /* constant in vc 
                              (must be first non register value) */
#define VT_LLOCAL    0x00f1  /* lvalue, offset on stack */
#define VT_LOCAL     0x00f2  /* offset on stack */
#define VT_CMP       0x00f3  /* the value is stored in processor flags (in vc) */
#define VT_JMP       0x00f4  /* value is the consequence of jmp true (even) */
#define VT_JMPI      0x00f5  /* value is the consequence of jmp false (odd) */
#define VT_LVAL      0x0100  /* var is an lvalue */
#define VT_SYM       0x0200  /* a symbol value is added */
#define VT_MUSTCAST  0x0400  /* value must be casted to be correct (used for
                                char/short stored in integer registers) */
#define VT_MUSTBOUND 0x0800  /* bound checking must be done before
                                dereferencing value */
#define VT_BOUNDED   0x8000  /* value is bounded. The address of the
                                bounding function call point is in vc */
#define VT_LVAL_BYTE     0x1000  /* lvalue is a byte */
#define VT_LVAL_SHORT    0x2000  /* lvalue is a short */
#define VT_LVAL_UNSIGNED 0x4000  /* lvalue is unsigned */
#define VT_LVAL_TYPE     (VT_LVAL_BYTE | VT_LVAL_SHORT | VT_LVAL_UNSIGNED)

/* types */
#define VT_INT        0  /* integer type */
#define VT_BYTE       1  /* signed byte type */
#define VT_SHORT      2  /* short type */
#define VT_VOID       3  /* void type */
#define VT_PTR        4  /* pointer */
#define VT_ENUM       5  /* enum definition */
#define VT_FUNC       6  /* function type */
#define VT_STRUCT     7  /* struct/union definition */
#define VT_FLOAT      8  /* IEEE float */
#define VT_DOUBLE     9  /* IEEE double */
#define VT_LDOUBLE   10  /* IEEE long double */
#define VT_BOOL      11  /* ISOC99 boolean type */
#define VT_LLONG     12  /* 64 bit integer */
#define VT_LONG      13  /* long integer (NEVER USED as type, only
                            during parsing) */
#define VT_BTYPE      0x000f /* mask for basic type */
#define VT_UNSIGNED   0x0010  /* unsigned type */
#define VT_ARRAY      0x0020  /* array type (also has VT_PTR) */
#define VT_BITFIELD   0x0040  /* bitfield modifier */
#define VT_CONSTANT   0x0800  /* const modifier */
#define VT_VOLATILE   0x1000  /* volatile modifier */
#define VT_SIGNED     0x2000  /* signed type */

/* storage */
#define VT_EXTERN  0x00000080  /* extern definition */
#define VT_STATIC  0x00000100  /* static variable */
#define VT_TYPEDEF 0x00000200  /* typedef definition */
#define VT_INLINE  0x00000400  /* inline definition */

#define VT_STRUCT_SHIFT 16   /* shift for bitfield shift values */

/* type mask (except storage) */
#define VT_STORAGE (VT_EXTERN | VT_STATIC | VT_TYPEDEF | VT_INLINE)
#define VT_TYPE    (~(VT_STORAGE))

/* token values */

/* warning: the following compare tokens depend on i386 asm code */
#define TOK_ULT 0x92
#define TOK_UGE 0x93
#define TOK_EQ  0x94
#define TOK_NE  0x95
#define TOK_ULE 0x96
#define TOK_UGT 0x97
#define TOK_Nset 0x98
#define TOK_Nclear 0x99
#define TOK_LT  0x9c
#define TOK_GE  0x9d
#define TOK_LE  0x9e
#define TOK_GT  0x9f

#define TOK_LAND  0xa0
#define TOK_LOR   0xa1

#define TOK_DEC   0xa2
#define TOK_MID   0xa3 /* inc/dec, to void constant */
#define TOK_INC   0xa4
#define TOK_UDIV  0xb0 /* unsigned division */
#define TOK_UMOD  0xb1 /* unsigned modulo */
#define TOK_PDIV  0xb2 /* fast division with undefined rounding for pointers */
#define TOK_CINT   0xb3 /* number in tokc */
#define TOK_CCHAR 0xb4 /* char constant in tokc */
#define TOK_STR   0xb5 /* pointer to string in tokc */
#define TOK_TWOSHARPS 0xb6 /* ## preprocessing token */
#define TOK_LCHAR    0xb7
#define TOK_LSTR     0xb8
#define TOK_CFLOAT   0xb9 /* float constant */
#define TOK_LINENUM  0xba /* line number info */
#define TOK_CDOUBLE  0xc0 /* double constant */
#define TOK_CLDOUBLE 0xc1 /* long double constant */
#define TOK_UMULL    0xc2 /* unsigned 32x32 -> 64 mul */
#define TOK_ADDC1    0xc3 /* add with carry generation */
#define TOK_ADDC2    0xc4 /* add with carry use */
#define TOK_SUBC1    0xc5 /* add with carry generation */
#define TOK_SUBC2    0xc6 /* add with carry use */
#define TOK_CUINT    0xc8 /* unsigned int constant */
#define TOK_CLLONG   0xc9 /* long long constant */
#define TOK_CULLONG  0xca /* unsigned long long constant */
#define TOK_ARROW    0xcb
#define TOK_DOTS     0xcc /* three dots */
#define TOK_SHR      0xcd /* unsigned shift right */
#define TOK_PPNUM    0xce /* preprocessor number */

#define TOK_SHL   0x01 /* shift left */
#define TOK_SAR   0x02 /* signed shift right */
  
/* assignement operators : normal operator or 0x80 */
#define TOK_A_MOD 0xa5
#define TOK_A_AND 0xa6
#define TOK_A_MUL 0xaa
#define TOK_A_ADD 0xab
#define TOK_A_SUB 0xad
#define TOK_A_DIV 0xaf
#define TOK_A_XOR 0xde
#define TOK_A_OR  0xfc
#define TOK_A_SHL 0x81
#define TOK_A_SAR 0x82

#ifndef offsetof
#define offsetof(type, field) ((size_t) &((type *)0)->field)
#endif

#ifndef countof
#define countof(tab) (sizeof(tab) / sizeof((tab)[0]))
#endif

#define TOK_EOF       (-1)  /* end of file */
#define TOK_LINEFEED  10    /* line feed */

/* all identificators and strings have token above that */
#define TOK_IDENT 256

/* only used for i386 asm opcodes definitions */
#define DEF_ASM(x) DEF(TOK_ASM_ ## x, #x)

#define DEF_BWL(x) \
 DEF(TOK_ASM_ ## x ## b, #x "b") \
 DEF(TOK_ASM_ ## x ## w, #x "w") \
 DEF(TOK_ASM_ ## x ## l, #x "l") \
 DEF(TOK_ASM_ ## x, #x)

#define DEF_WL(x) \
 DEF(TOK_ASM_ ## x ## w, #x "w") \
 DEF(TOK_ASM_ ## x ## l, #x "l") \
 DEF(TOK_ASM_ ## x, #x)

#define DEF_FP1(x) \
 DEF(TOK_ASM_ ## f ## x ## s, "f" #x "s") \
 DEF(TOK_ASM_ ## fi ## x ## l, "fi" #x "l") \
 DEF(TOK_ASM_ ## f ## x ## l, "f" #x "l") \
 DEF(TOK_ASM_ ## fi ## x ## s, "fi" #x "s")

#define DEF_FP(x) \
 DEF(TOK_ASM_ ## f ## x, "f" #x ) \
 DEF(TOK_ASM_ ## f ## x ## p, "f" #x "p") \
 DEF_FP1(x)

#define DEF_ASMTEST(x) \
 DEF_ASM(x ## o) \
 DEF_ASM(x ## no) \
 DEF_ASM(x ## b) \
 DEF_ASM(x ## c) \
 DEF_ASM(x ## nae) \
 DEF_ASM(x ## nb) \
 DEF_ASM(x ## nc) \
 DEF_ASM(x ## ae) \
 DEF_ASM(x ## e) \
 DEF_ASM(x ## z) \
 DEF_ASM(x ## ne) \
 DEF_ASM(x ## nz) \
 DEF_ASM(x ## be) \
 DEF_ASM(x ## na) \
 DEF_ASM(x ## nbe) \
 DEF_ASM(x ## a) \
 DEF_ASM(x ## s) \
 DEF_ASM(x ## ns) \
 DEF_ASM(x ## p) \
 DEF_ASM(x ## pe) \
 DEF_ASM(x ## np) \
 DEF_ASM(x ## po) \
 DEF_ASM(x ## l) \
 DEF_ASM(x ## nge) \
 DEF_ASM(x ## nl) \
 DEF_ASM(x ## ge) \
 DEF_ASM(x ## le) \
 DEF_ASM(x ## ng) \
 DEF_ASM(x ## nle) \
 DEF_ASM(x ## g)

#define TOK_ASM_int TOK_INT

enum tcc_token {
    TOK_LAST = TOK_IDENT - 1,
#define DEF(id, str) id,
#include "tcctok.h"
#undef DEF
};

#define TOK_UIDENT TOK_DEFINE

#ifdef _WIN32
#define snprintf _snprintf
#define vsnprintf _vsnprintf
#ifndef __GNUC__
  #define strtold (long double)strtod
  #define strtof (float)strtod
  #define strtoll (long long)strtol
#endif
#elif defined(TCC_UCLIBC) || defined(__FreeBSD__) || defined(__DragonFly__) \
    || defined(__OpenBSD__)
/* currently incorrect */
long double strtold(const char *nptr, char **endptr)
{
    return (long double)strtod(nptr, endptr);
}
float strtof(const char *nptr, char **endptr)
{
    return (float)strtod(nptr, endptr);
}
#else
/* XXX: need to define this to use them in non ISOC99 context */
extern float strtof (const char *__nptr, char **__endptr);
extern long double strtold (const char *__nptr, char **__endptr);
#endif

#ifdef _WIN32
#define IS_PATHSEP(c) (c == '/' || c == '\\')
#define IS_ABSPATH(p) (IS_PATHSEP(p[0]) || (p[0] && p[1] == ':' && IS_PATHSEP(p[2])))
#define PATHCMP stricmp
#else
#define IS_PATHSEP(c) (c == '/')
#define IS_ABSPATH(p) IS_PATHSEP(p[0])
#define PATHCMP strcmp
#endif

void error(const char *fmt, ...);
void error_noabort(const char *fmt, ...);
void warning(const char *fmt, ...);

void tcc_set_lib_path_w32(TCCState *s);
int tcc_set_flag(TCCState *s, const char *flag_name, int value);
void tcc_print_stats(TCCState *s, int64_t total_time);

void tcc_free(void *ptr);
void *tcc_malloc(unsigned long size);
void *tcc_mallocz(unsigned long size);
void *tcc_realloc(void *ptr, unsigned long size);
char *tcc_strdup(const char *str);

char *tcc_basename(const char *name);
char *tcc_fileextension (const char *name);
char *pstrcpy(char *buf, int buf_size, const char *s);
char *pstrcat(char *buf, int buf_size, const char *s);
void dynarray_add(void ***ptab, int *nb_ptr, void *data);
void dynarray_reset(void *pp, int *n);

#ifdef CONFIG_TCC_BACKTRACE
extern int num_callers;
extern const char **rt_bound_error_msg;
#endif

/* true if float/double/long double type */
static inline int is_float(int t)
{
    int bt;
    bt = t & VT_BTYPE;
    return bt == VT_LDOUBLE || bt == VT_DOUBLE || bt == VT_FLOAT;
}

/* space exlcuding newline */
static inline int is_space(int ch)
{
    return ch == ' ' || ch == '\t' || ch == '\v' || ch == '\f' || ch == '\r';
}

