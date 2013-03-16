#ifndef _STDARG_H
#define _STDARG_H

#ifdef __x86_64__
#include <stdlib.h>

/* GCC compatible definition of va_list. */
struct __va_list_struct {
    unsigned int gp_offset;
    unsigned int fp_offset;
    union {
        unsigned int overflow_offset;
        char *overflow_arg_area;
    };
    char *reg_save_area;
};

typedef struct __va_list_struct *va_list;

/* we use __builtin_(malloc|free) to avoid #define malloc tcc_malloc */
/* XXX: this lacks the support of aggregated types. */
#define va_start(ap, last)                                              \
    (ap = (va_list)__builtin_malloc(sizeof(struct __va_list_struct)),   \
     *ap = *(struct __va_list_struct*)(                                 \
         (char*)__builtin_frame_address(0) - 16),                       \
     ap->overflow_arg_area = ((char *)__builtin_frame_address(0) +      \
                              ap->overflow_offset),                     \
     ap->reg_save_area = (char *)__builtin_frame_address(0) - 176 - 16  \
        )
#define va_arg(ap, type)                                        \
    (*(type*)(__builtin_types_compatible_p(type, long double)   \
              ? (ap->overflow_arg_area += 16,                   \
                 ap->overflow_arg_area - 16)                    \
              : __builtin_types_compatible_p(type, double)      \
              ? (ap->fp_offset < 128 + 48                       \
                 ? (ap->fp_offset += 16,                        \
                    ap->reg_save_area + ap->fp_offset - 16)     \
                 : (ap->overflow_arg_area += 8,                 \
                    ap->overflow_arg_area - 8))                 \
              : (ap->gp_offset < 48                             \
                 ? (ap->gp_offset += 8,                         \
                    ap->reg_save_area + ap->gp_offset - 8)      \
                 : (ap->overflow_arg_area += 8,                 \
                    ap->overflow_arg_area - 8))                 \
        ))
#define va_copy(dest, src)                                      \
    ((dest) = (va_list)malloc(sizeof(struct __va_list_struct)), \
     *(dest) = *(src))
#define va_end(ap) __builtin_free(ap)

#else

typedef char *va_list;

/* only correct for i386 */
#define va_start(ap,last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)
#define va_arg(ap,type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))
#define va_copy(dest, src) (dest) = (src)
#define va_end(ap)

#endif

/* fix a buggy dependency on GCC in libio.h */
typedef va_list __gnuc_va_list;
#define _VA_LIST_DEFINED

#endif /* _STDARG_H */
