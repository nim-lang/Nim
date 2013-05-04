/*
 *  Tiny C Memory and bounds checker
 * 
 *  Copyright (c) 2002 Fabrice Bellard
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
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#if !defined(__FreeBSD__) && !defined(__DragonFly__) && !defined(__OpenBSD__)
#include <malloc.h>
#endif

//#define BOUND_DEBUG

/* define so that bound array is static (faster, but use memory if
   bound checking not used) */
//#define BOUND_STATIC

/* use malloc hooks. Currently the code cannot be reliable if no hooks */
#define CONFIG_TCC_MALLOC_HOOKS

#define HAVE_MEMALIGN

#if defined(__FreeBSD__) || defined(__DragonFly__) || defined(__dietlibc__) \
    || defined(__UCLIBC__) || defined(__OpenBSD__)
#warning Bound checking not fully supported in this environment.
#undef CONFIG_TCC_MALLOC_HOOKS
#undef HAVE_MEMALIGN
#endif

#define BOUND_T1_BITS 13
#define BOUND_T2_BITS 11
#define BOUND_T3_BITS (32 - BOUND_T1_BITS - BOUND_T2_BITS)

#define BOUND_T1_SIZE (1 << BOUND_T1_BITS)
#define BOUND_T2_SIZE (1 << BOUND_T2_BITS)
#define BOUND_T3_SIZE (1 << BOUND_T3_BITS)
#define BOUND_E_BITS  4

#define BOUND_T23_BITS (BOUND_T2_BITS + BOUND_T3_BITS)
#define BOUND_T23_SIZE (1 << BOUND_T23_BITS)


/* this pointer is generated when bound check is incorrect */
#define INVALID_POINTER ((void *)(-2))
/* size of an empty region */
#define EMPTY_SIZE        0xffffffff
/* size of an invalid region */
#define INVALID_SIZE      0

typedef struct BoundEntry {
    unsigned long start;
    unsigned long size;
    struct BoundEntry *next;
    unsigned long is_invalid; /* true if pointers outside region are invalid */
} BoundEntry;

/* external interface */
void __bound_init(void);
void __bound_new_region(void *p, unsigned long size);
int __bound_delete_region(void *p);

#define FASTCALL __attribute__((regparm(3)))

void *__bound_malloc(size_t size, const void *caller);
void *__bound_memalign(size_t size, size_t align, const void *caller);
void __bound_free(void *ptr, const void *caller);
void *__bound_realloc(void *ptr, size_t size, const void *caller);
static void *libc_malloc(size_t size);
static void libc_free(void *ptr);
static void install_malloc_hooks(void);
static void restore_malloc_hooks(void);

#ifdef CONFIG_TCC_MALLOC_HOOKS
static void *saved_malloc_hook;
static void *saved_free_hook;
static void *saved_realloc_hook;
static void *saved_memalign_hook;
#endif

/* linker definitions */
extern char _end;

/* TCC definitions */
extern char __bounds_start; /* start of static bounds table */
/* error message, just for TCC */
const char *__bound_error_msg;

/* runtime error output */
extern void rt_error(unsigned long pc, const char *fmt, ...);

#ifdef BOUND_STATIC
static BoundEntry *__bound_t1[BOUND_T1_SIZE]; /* page table */
#else
static BoundEntry **__bound_t1; /* page table */
#endif
static BoundEntry *__bound_empty_t2;   /* empty page, for unused pages */
static BoundEntry *__bound_invalid_t2; /* invalid page, for invalid pointers */

static BoundEntry *__bound_find_region(BoundEntry *e1, void *p)
{
    unsigned long addr, tmp;
    BoundEntry *e;

    e = e1;
    while (e != NULL) {
        addr = (unsigned long)p;
        addr -= e->start;
        if (addr <= e->size) {
            /* put region at the head */
            tmp = e1->start;
            e1->start = e->start;
            e->start = tmp;
            tmp = e1->size;
            e1->size = e->size;
            e->size = tmp;
            return e1;
        }
        e = e->next;
    }
    /* no entry found: return empty entry or invalid entry */
    if (e1->is_invalid)
        return __bound_invalid_t2;
    else
        return __bound_empty_t2;
}

/* print a bound error message */
static void bound_error(const char *fmt, ...)
{
    __bound_error_msg = fmt;
    *(int *)0 = 0; /* force a runtime error */
}

static void bound_alloc_error(void)
{
    bound_error("not enough memory for bound checking code");
}

/* currently, tcc cannot compile that because we use GNUC extensions */
#if !defined(__TINYC__)

/* return '(p + offset)' for pointer arithmetic (a pointer can reach
   the end of a region in this case */
void * FASTCALL __bound_ptr_add(void *p, int offset)
{
    unsigned long addr = (unsigned long)p;
    BoundEntry *e;
#if defined(BOUND_DEBUG)
    printf("add: 0x%x %d\n", (int)p, offset);
#endif

    e = __bound_t1[addr >> (BOUND_T2_BITS + BOUND_T3_BITS)];
    e = (BoundEntry *)((char *)e + 
                       ((addr >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
                        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS)));
    addr -= e->start;
    if (addr > e->size) {
        e = __bound_find_region(e, p);
        addr = (unsigned long)p - e->start;
    }
    addr += offset;
    if (addr > e->size)
        return INVALID_POINTER; /* return an invalid pointer */
    return p + offset;
}

/* return '(p + offset)' for pointer indirection (the resulting must
   be strictly inside the region */
#define BOUND_PTR_INDIR(dsize)                                          \
void * FASTCALL __bound_ptr_indir ## dsize (void *p, int offset)        \
{                                                                       \
    unsigned long addr = (unsigned long)p;                              \
    BoundEntry *e;                                                      \
                                                                        \
    e = __bound_t1[addr >> (BOUND_T2_BITS + BOUND_T3_BITS)];            \
    e = (BoundEntry *)((char *)e +                                      \
                       ((addr >> (BOUND_T3_BITS - BOUND_E_BITS)) &      \
                        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS)));        \
    addr -= e->start;                                                   \
    if (addr > e->size) {                                               \
        e = __bound_find_region(e, p);                                  \
        addr = (unsigned long)p - e->start;                             \
    }                                                                   \
    addr += offset + dsize;                                             \
    if (addr > e->size)                                                 \
        return INVALID_POINTER; /* return an invalid pointer */         \
    return p + offset;                                                  \
}

#ifdef __i386__
/* return the frame pointer of the caller */
#define GET_CALLER_FP(fp)\
{\
    unsigned long *fp1;\
    __asm__ __volatile__ ("movl %%ebp,%0" :"=g" (fp1));\
    fp = fp1[0];\
}
#else
#error put code to extract the calling frame pointer
#endif

/* called when entering a function to add all the local regions */
void FASTCALL __bound_local_new(void *p1) 
{
    unsigned long addr, size, fp, *p = p1;
    GET_CALLER_FP(fp);
    for(;;) {
        addr = p[0];
        if (addr == 0)
            break;
        addr += fp;
        size = p[1];
        p += 2;
        __bound_new_region((void *)addr, size);
    }
}

/* called when leaving a function to delete all the local regions */
void FASTCALL __bound_local_delete(void *p1) 
{
    unsigned long addr, fp, *p = p1;
    GET_CALLER_FP(fp);
    for(;;) {
        addr = p[0];
        if (addr == 0)
            break;
        addr += fp;
        p += 2;
        __bound_delete_region((void *)addr);
    }
}

#else

void __bound_local_new(void *p) 
{
}
void __bound_local_delete(void *p) 
{
}

void *__bound_ptr_add(void *p, int offset)
{
    return p + offset;
}

#define BOUND_PTR_INDIR(dsize)                               \
void *__bound_ptr_indir ## dsize (void *p, int offset)       \
{                                                            \
    return p + offset;                                       \
}
#endif

BOUND_PTR_INDIR(1)
BOUND_PTR_INDIR(2)
BOUND_PTR_INDIR(4)
BOUND_PTR_INDIR(8)
BOUND_PTR_INDIR(12)
BOUND_PTR_INDIR(16)

static BoundEntry *__bound_new_page(void)
{
    BoundEntry *page;
    int i;

    page = libc_malloc(sizeof(BoundEntry) * BOUND_T2_SIZE);
    if (!page)
        bound_alloc_error();
    for(i=0;i<BOUND_T2_SIZE;i++) {
        /* put empty entries */
        page[i].start = 0;
        page[i].size = EMPTY_SIZE;
        page[i].next = NULL;
        page[i].is_invalid = 0;
    }
    return page;
}

/* currently we use malloc(). Should use bound_new_page() */
static BoundEntry *bound_new_entry(void)
{
    BoundEntry *e;
    e = libc_malloc(sizeof(BoundEntry));
    return e;
}

static void bound_free_entry(BoundEntry *e)
{
    libc_free(e);
}

static inline BoundEntry *get_page(int index)
{
    BoundEntry *page;
    page = __bound_t1[index];
    if (page == __bound_empty_t2 || page == __bound_invalid_t2) {
        /* create a new page if necessary */
        page = __bound_new_page();
        __bound_t1[index] = page;
    }
    return page;
}

/* mark a region as being invalid (can only be used during init) */
static void mark_invalid(unsigned long addr, unsigned long size)
{
    unsigned long start, end;
    BoundEntry *page;
    int t1_start, t1_end, i, j, t2_start, t2_end;

    start = addr;
    end = addr + size;

    t2_start = (start + BOUND_T3_SIZE - 1) >> BOUND_T3_BITS;
    if (end != 0)
        t2_end = end >> BOUND_T3_BITS;
    else
        t2_end = 1 << (BOUND_T1_BITS + BOUND_T2_BITS);

#if 0
    printf("mark_invalid: start = %x %x\n", t2_start, t2_end);
#endif
    
    /* first we handle full pages */
    t1_start = (t2_start + BOUND_T2_SIZE - 1) >> BOUND_T2_BITS;
    t1_end = t2_end >> BOUND_T2_BITS;

    i = t2_start & (BOUND_T2_SIZE - 1);
    j = t2_end & (BOUND_T2_SIZE - 1);
    
    if (t1_start == t1_end) {
        page = get_page(t2_start >> BOUND_T2_BITS);
        for(; i < j; i++) {
            page[i].size = INVALID_SIZE;
            page[i].is_invalid = 1;
        }
    } else {
        if (i > 0) {
            page = get_page(t2_start >> BOUND_T2_BITS);
            for(; i < BOUND_T2_SIZE; i++) {
                page[i].size = INVALID_SIZE;
                page[i].is_invalid = 1;
            }
        }
        for(i = t1_start; i < t1_end; i++) {
            __bound_t1[i] = __bound_invalid_t2;
        }
        if (j != 0) {
            page = get_page(t1_end);
            for(i = 0; i < j; i++) {
                page[i].size = INVALID_SIZE;
                page[i].is_invalid = 1;
            }
        }
    }
}

void __bound_init(void)
{
    int i;
    BoundEntry *page;
    unsigned long start, size;
    int *p;

    /* save malloc hooks and install bound check hooks */
    install_malloc_hooks();

#ifndef BOUND_STATIC
    __bound_t1 = libc_malloc(BOUND_T1_SIZE * sizeof(BoundEntry *));
    if (!__bound_t1)
        bound_alloc_error();
#endif
    __bound_empty_t2 = __bound_new_page();
    for(i=0;i<BOUND_T1_SIZE;i++) {
        __bound_t1[i] = __bound_empty_t2;
    }

    page = __bound_new_page();
    for(i=0;i<BOUND_T2_SIZE;i++) {
        /* put invalid entries */
        page[i].start = 0;
        page[i].size = INVALID_SIZE;
        page[i].next = NULL;
        page[i].is_invalid = 1;
    }
    __bound_invalid_t2 = page;

    /* invalid pointer zone */
    start = (unsigned long)INVALID_POINTER & ~(BOUND_T23_SIZE - 1);
    size = BOUND_T23_SIZE;
    mark_invalid(start, size);

#if !defined(__TINYC__) && defined(CONFIG_TCC_MALLOC_HOOKS)
    /* malloc zone is also marked invalid. can only use that with
       hooks because all libs should use the same malloc. The solution
       would be to build a new malloc for tcc. */
    start = (unsigned long)&_end;
    size = 128 * 0x100000;
    mark_invalid(start, size);
#endif

    /* add all static bound check values */
    p = (int *)&__bounds_start;
    while (p[0] != 0) {
        __bound_new_region((void *)p[0], p[1]);
        p += 2;
    }
}

static inline void add_region(BoundEntry *e, 
                              unsigned long start, unsigned long size)
{
    BoundEntry *e1;
    if (e->start == 0) {
        /* no region : add it */
        e->start = start;
        e->size = size;
    } else {
        /* already regions in the list: add it at the head */
        e1 = bound_new_entry();
        e1->start = e->start;
        e1->size = e->size;
        e1->next = e->next;
        e->start = start;
        e->size = size;
        e->next = e1;
    }
}

/* create a new region. It should not already exist in the region list */
void __bound_new_region(void *p, unsigned long size)
{
    unsigned long start, end;
    BoundEntry *page, *e, *e2;
    int t1_start, t1_end, i, t2_start, t2_end;

    start = (unsigned long)p;
    end = start + size;
    t1_start = start >> (BOUND_T2_BITS + BOUND_T3_BITS);
    t1_end = end >> (BOUND_T2_BITS + BOUND_T3_BITS);

    /* start */
    page = get_page(t1_start);
    t2_start = (start >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS);
    t2_end = (end >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS);
#ifdef BOUND_DEBUG
    printf("new %lx %lx %x %x %x %x\n", 
           start, end, t1_start, t1_end, t2_start, t2_end);
#endif

    e = (BoundEntry *)((char *)page + t2_start);
    add_region(e, start, size);

    if (t1_end == t1_start) {
        /* same ending page */
        e2 = (BoundEntry *)((char *)page + t2_end);
        if (e2 > e) {
            e++;
            for(;e<e2;e++) {
                e->start = start;
                e->size = size;
            }
            add_region(e, start, size);
        }
    } else {
        /* mark until end of page */
        e2 = page + BOUND_T2_SIZE;
        e++;
        for(;e<e2;e++) {
            e->start = start;
            e->size = size;
        }
        /* mark intermediate pages, if any */
        for(i=t1_start+1;i<t1_end;i++) {
            page = get_page(i);
            e2 = page + BOUND_T2_SIZE;
            for(e=page;e<e2;e++) {
                e->start = start;
                e->size = size;
            }
        }
        /* last page */
        page = get_page(t1_end);
        e2 = (BoundEntry *)((char *)page + t2_end);
        for(e=page;e<e2;e++) {
            e->start = start;
            e->size = size;
        }
        add_region(e, start, size);
    }
}

/* delete a region */
static inline void delete_region(BoundEntry *e, 
                                 void *p, unsigned long empty_size)
{
    unsigned long addr;
    BoundEntry *e1;

    addr = (unsigned long)p;
    addr -= e->start;
    if (addr <= e->size) {
        /* region found is first one */
        e1 = e->next;
        if (e1 == NULL) {
            /* no more region: mark it empty */
            e->start = 0;
            e->size = empty_size;
        } else {
            /* copy next region in head */
            e->start = e1->start;
            e->size = e1->size;
            e->next = e1->next;
            bound_free_entry(e1);
        }
    } else {
        /* find the matching region */
        for(;;) {
            e1 = e;
            e = e->next;
            /* region not found: do nothing */
            if (e == NULL)
                break;
            addr = (unsigned long)p - e->start;
            if (addr <= e->size) {
                /* found: remove entry */
                e1->next = e->next;
                bound_free_entry(e);
                break;
            }
        }
    }
}

/* WARNING: 'p' must be the starting point of the region. */
/* return non zero if error */
int __bound_delete_region(void *p)
{
    unsigned long start, end, addr, size, empty_size;
    BoundEntry *page, *e, *e2;
    int t1_start, t1_end, t2_start, t2_end, i;

    start = (unsigned long)p;
    t1_start = start >> (BOUND_T2_BITS + BOUND_T3_BITS);
    t2_start = (start >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS);
    
    /* find region size */
    page = __bound_t1[t1_start];
    e = (BoundEntry *)((char *)page + t2_start);
    addr = start - e->start;
    if (addr > e->size)
        e = __bound_find_region(e, p);
    /* test if invalid region */
    if (e->size == EMPTY_SIZE || (unsigned long)p != e->start) 
        return -1;
    /* compute the size we put in invalid regions */
    if (e->is_invalid)
        empty_size = INVALID_SIZE;
    else
        empty_size = EMPTY_SIZE;
    size = e->size;
    end = start + size;

    /* now we can free each entry */
    t1_end = end >> (BOUND_T2_BITS + BOUND_T3_BITS);
    t2_end = (end >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS);

    delete_region(e, p, empty_size);
    if (t1_end == t1_start) {
        /* same ending page */
        e2 = (BoundEntry *)((char *)page + t2_end);
        if (e2 > e) {
            e++;
            for(;e<e2;e++) {
                e->start = 0;
                e->size = empty_size;
            }
            delete_region(e, p, empty_size);
        }
    } else {
        /* mark until end of page */
        e2 = page + BOUND_T2_SIZE;
        e++;
        for(;e<e2;e++) {
            e->start = 0;
            e->size = empty_size;
        }
        /* mark intermediate pages, if any */
        /* XXX: should free them */
        for(i=t1_start+1;i<t1_end;i++) {
            page = get_page(i);
            e2 = page + BOUND_T2_SIZE;
            for(e=page;e<e2;e++) {
                e->start = 0;
                e->size = empty_size;
            }
        }
        /* last page */
        page = get_page(t2_end);
        e2 = (BoundEntry *)((char *)page + t2_end);
        for(e=page;e<e2;e++) {
            e->start = 0;
            e->size = empty_size;
        }
        delete_region(e, p, empty_size);
    }
    return 0;
}

/* return the size of the region starting at p, or EMPTY_SIZE if non
   existant region. */
static unsigned long get_region_size(void *p)
{
    unsigned long addr = (unsigned long)p;
    BoundEntry *e;

    e = __bound_t1[addr >> (BOUND_T2_BITS + BOUND_T3_BITS)];
    e = (BoundEntry *)((char *)e + 
                       ((addr >> (BOUND_T3_BITS - BOUND_E_BITS)) & 
                        ((BOUND_T2_SIZE - 1) << BOUND_E_BITS)));
    addr -= e->start;
    if (addr > e->size)
        e = __bound_find_region(e, p);
    if (e->start != (unsigned long)p)
        return EMPTY_SIZE;
    return e->size;
}

/* patched memory functions */

static void install_malloc_hooks(void)
{
#ifdef CONFIG_TCC_MALLOC_HOOKS
    saved_malloc_hook = __malloc_hook;
    saved_free_hook = __free_hook;
    saved_realloc_hook = __realloc_hook;
    saved_memalign_hook = __memalign_hook;
    __malloc_hook = __bound_malloc;
    __free_hook = __bound_free;
    __realloc_hook = __bound_realloc;
    __memalign_hook = __bound_memalign;
#endif
}

static void restore_malloc_hooks(void)
{
#ifdef CONFIG_TCC_MALLOC_HOOKS
    __malloc_hook = saved_malloc_hook;
    __free_hook = saved_free_hook;
    __realloc_hook = saved_realloc_hook;
    __memalign_hook = saved_memalign_hook;
#endif
}

static void *libc_malloc(size_t size)
{
    void *ptr;
    restore_malloc_hooks();
    ptr = malloc(size);
    install_malloc_hooks();
    return ptr;
}

static void libc_free(void *ptr)
{
    restore_malloc_hooks();
    free(ptr);
    install_malloc_hooks();
}

/* XXX: we should use a malloc which ensure that it is unlikely that
   two malloc'ed data have the same address if 'free' are made in
   between. */
void *__bound_malloc(size_t size, const void *caller)
{
    void *ptr;
    
    /* we allocate one more byte to ensure the regions will be
       separated by at least one byte. With the glibc malloc, it may
       be in fact not necessary */
    ptr = libc_malloc(size + 1);
    
    if (!ptr)
        return NULL;
    __bound_new_region(ptr, size);
    return ptr;
}

void *__bound_memalign(size_t size, size_t align, const void *caller)
{
    void *ptr;

    restore_malloc_hooks();

#ifndef HAVE_MEMALIGN
    if (align > 4) {
        /* XXX: handle it ? */
        ptr = NULL;
    } else {
        /* we suppose that malloc aligns to at least four bytes */
        ptr = malloc(size + 1);
    }
#else
    /* we allocate one more byte to ensure the regions will be
       separated by at least one byte. With the glibc malloc, it may
       be in fact not necessary */
    ptr = memalign(size + 1, align);
#endif
    
    install_malloc_hooks();
    
    if (!ptr)
        return NULL;
    __bound_new_region(ptr, size);
    return ptr;
}

void __bound_free(void *ptr, const void *caller)
{
    if (ptr == NULL)
        return;
    if (__bound_delete_region(ptr) != 0)
        bound_error("freeing invalid region");

    libc_free(ptr);
}

void *__bound_realloc(void *ptr, size_t size, const void *caller)
{
    void *ptr1;
    int old_size;

    if (size == 0) {
        __bound_free(ptr, caller);
        return NULL;
    } else {
        ptr1 = __bound_malloc(size, caller);
        if (ptr == NULL || ptr1 == NULL)
            return ptr1;
        old_size = get_region_size(ptr);
        if (old_size == EMPTY_SIZE)
            bound_error("realloc'ing invalid pointer");
        memcpy(ptr1, ptr, old_size);
        __bound_free(ptr, caller);
        return ptr1;
    }
}

#ifndef CONFIG_TCC_MALLOC_HOOKS
void *__bound_calloc(size_t nmemb, size_t size)
{
    void *ptr;
    size = size * nmemb;
    ptr = __bound_malloc(size, NULL);
    if (!ptr)
        return NULL;
    memset(ptr, 0, size);
    return ptr;
}
#endif

#if 0
static void bound_dump(void)
{
    BoundEntry *page, *e;
    int i, j;

    printf("region dump:\n");
    for(i=0;i<BOUND_T1_SIZE;i++) {
        page = __bound_t1[i];
        for(j=0;j<BOUND_T2_SIZE;j++) {
            e = page + j;
            /* do not print invalid or empty entries */
            if (e->size != EMPTY_SIZE && e->start != 0) {
                printf("%08x:", 
                       (i << (BOUND_T2_BITS + BOUND_T3_BITS)) + 
                       (j << BOUND_T3_BITS));
                do {
                    printf(" %08lx:%08lx", e->start, e->start + e->size);
                    e = e->next;
                } while (e != NULL);
                printf("\n");
            }
        }
    }
}
#endif

/* some useful checked functions */

/* check that (p ... p + size - 1) lies inside 'p' region, if any */
static void __bound_check(const void *p, size_t size)
{
    if (size == 0)
        return;
    p = __bound_ptr_add((void *)p, size);
    if (p == INVALID_POINTER)
        bound_error("invalid pointer");
}

void *__bound_memcpy(void *dst, const void *src, size_t size)
{
    __bound_check(dst, size);
    __bound_check(src, size);
    /* check also region overlap */
    if (src >= dst && src < dst + size)
        bound_error("overlapping regions in memcpy()");
    return memcpy(dst, src, size);
}

void *__bound_memmove(void *dst, const void *src, size_t size)
{
    __bound_check(dst, size);
    __bound_check(src, size);
    return memmove(dst, src, size);
}

void *__bound_memset(void *dst, int c, size_t size)
{
    __bound_check(dst, size);
    return memset(dst, c, size);
}

/* XXX: could be optimized */
int __bound_strlen(const char *s)
{
    const char *p;
    int len;

    len = 0;
    for(;;) {
        p = __bound_ptr_indir1((char *)s, len);
        if (p == INVALID_POINTER)
            bound_error("bad pointer in strlen()");
        if (*p == '\0')
            break;
        len++;
    }
    return len;
}

char *__bound_strcpy(char *dst, const char *src)
{
    int len;
    len = __bound_strlen(src);
    return __bound_memcpy(dst, src, len + 1);
}

