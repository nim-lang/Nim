/* 
 * Two Levels Segregate Fit memory allocator (TLSF)
 * Version 2.4.3
 *
 * Written by Miguel Masmano Tello <mimastel@doctor.upv.es>
 *
 * Thanks to Ismael Ripoll for his suggestions and reviews
 *
 * Copyright (C) 2008, 2007, 2006, 2005, 2004
 *
 * This code is released using a dual license strategy: GPL/LGPL
 * You can choose the licence that better fits your requirements.
 *
 * Released under the terms of the GNU General Public License Version 2.0
 * Released under the terms of the GNU Lesser General Public License Version 2.1
 *
 */

/*
 * Code contributions:
 *
 * (Jul 28 2007)  Herman ten Brugge <hermantenbrugge@home.nl>:
 *
 * - Add 64 bit support. It now runs on x86_64 and solaris64.
 * - I also tested this on vxworks/32and solaris/32 and i386/32 processors.
 * - Remove assembly code. I could not measure any performance difference 
 *   on my core2 processor. This also makes the code more portable.
 * - Moved defines/typedefs from tlsf.h to tlsf.c
 * - Changed MIN_BLOCK_SIZE to sizeof (free_ptr_t) and BHDR_OVERHEAD to 
 *   (sizeof (bhdr_t) - MIN_BLOCK_SIZE). This does not change the fact 
 *    that the minumum size is still sizeof 
 *   (bhdr_t).
 * - Changed all C++ comment style to C style. (// -> /.* ... *./)
 * - Used ls_bit instead of ffs and ms_bit instead of fls. I did this to 
 *   avoid confusion with the standard ffs function which returns 
 *   different values.
 * - Created set_bit/clear_bit fuctions because they are not present 
 *   on x86_64.
 * - Added locking support + extra file target.h to show how to use it.
 * - Added get_used_size function (REMOVED in 2.4)
 * - Added rtl_realloc and rtl_calloc function
 * - Implemented realloc clever support.
 * - Added some test code in the example directory.
 *        
 *
 * (Oct 23 2006) Adam Scislowicz: 
 *
 * - Support for ARMv5 implemented
 *
 */

/************************************************************************/

#define USE_SBRK        (1) 
#define USE_MMAP        (1) 
#define TLSF_STATISTIC  (1)

#include <stdio.h>
#include <string.h>

#ifndef TLSF_USE_LOCKS
#define  TLSF_USE_LOCKS   (0)
#endif

#ifndef TLSF_STATISTIC
#define  TLSF_STATISTIC   (0)
#endif

#ifndef USE_MMAP
#define  USE_MMAP   (0)
#endif

#ifndef USE_SBRK
#define  USE_SBRK   (0)
#endif


#if TLSF_USE_LOCKS
#include "target.h"
#else
#define TLSF_CREATE_LOCK(_unused_)   do {} while(0)
#define TLSF_DESTROY_LOCK(_unused_)  do {} while(0) 
#define TLSF_ACQUIRE_LOCK(_unused_)  do {} while(0)
#define TLSF_RELEASE_LOCK(_unused_)  do {} while(0)
#endif

#if TLSF_STATISTIC
#define  TLSF_ADD_SIZE(tlsf, b) do {                  \
    tlsf->used_size += (b->size & BLOCK_SIZE) + BHDR_OVERHEAD;  \
    if (tlsf->used_size > tlsf->max_size)             \
      tlsf->max_size = tlsf->used_size;            \
    } while(0)

#define  TLSF_REMOVE_SIZE(tlsf, b) do {                \
    tlsf->used_size -= (b->size & BLOCK_SIZE) + BHDR_OVERHEAD;  \
  } while(0)
#else
#define  TLSF_ADD_SIZE(tlsf, b)       do{}while(0)
#define  TLSF_REMOVE_SIZE(tlsf, b)    do{}while(0)
#endif

#if USE_MMAP || USE_SBRK
#include <unistd.h>
#endif

#if USE_MMAP
#include <sys/mman.h>
#endif

#include "tlsf.h"

#if !defined(__GNUC__)
#ifndef __inline__
#define __inline__
#endif
#endif

/* The  debug functions  only can  be used  when _DEBUG_TLSF_  is set. */
#ifndef _DEBUG_TLSF_
#define _DEBUG_TLSF_  (0)
#endif

/*************************************************************************/
/* Definition of the structures used by TLSF */


/* Some IMPORTANT TLSF parameters */
/* Unlike the preview TLSF versions, now they are statics */
#define BLOCK_ALIGN (sizeof(void *) * 2)

#define MAX_FLI    (30)
#define MAX_LOG2_SLI  (5)
#define MAX_SLI    (1 << MAX_LOG2_SLI)     /* MAX_SLI = 2^MAX_LOG2_SLI */

#define FLI_OFFSET  (6)     /* tlsf structure just will manage blocks bigger */
/* than 128 bytes */
#define SMALL_BLOCK  (128)
#define REAL_FLI  (MAX_FLI - FLI_OFFSET)
#define MIN_BLOCK_SIZE  (sizeof (free_ptr_t))
#define BHDR_OVERHEAD  (sizeof (bhdr_t) - MIN_BLOCK_SIZE)
#define TLSF_SIGNATURE  (0x2A59FA59)

#define  PTR_MASK  (sizeof(void *) - 1)
#define BLOCK_SIZE  (0xFFFFFFFF - PTR_MASK)

#define GET_NEXT_BLOCK(_addr, _r) ((bhdr_t *) ((char *) (_addr) + (_r)))
#define  MEM_ALIGN      ((BLOCK_ALIGN) - 1)
#define ROUNDUP_SIZE(_r)          (((_r) + MEM_ALIGN) & ~MEM_ALIGN)
#define ROUNDDOWN_SIZE(_r)        ((_r) & ~MEM_ALIGN)
#define ROUNDUP(_x, _v)           ((((~(_x)) + 1) & ((_v)-1)) + (_x))

#define BLOCK_STATE  (0x1)
#define PREV_STATE  (0x2)

/* bit 0 of the block size */
#define FREE_BLOCK  (0x1)
#define USED_BLOCK  (0x0)

/* bit 1 of the block size */
#define PREV_FREE  (0x2)
#define PREV_USED  (0x0)


#define DEFAULT_AREA_SIZE (1024*10)

#ifdef USE_MMAP
#define PAGE_SIZE (getpagesize())
#endif

#define PRINT_MSG(fmt, args...) printf(fmt, ## args)
#define ERROR_MSG(fmt, args...) printf(fmt, ## args)

typedef unsigned int u32_t;     /* NOTE: Make sure that this type is 4 bytes long on your computer */
typedef unsigned char u8_t;     /* NOTE: Make sure that this type is 1 byte on your computer */

typedef struct free_ptr_struct {
    struct bhdr_struct *prev;
    struct bhdr_struct *next;
} free_ptr_t;

typedef struct bhdr_struct {
    /* This pointer is just valid if the first bit of size is set */
    struct bhdr_struct *prev_hdr;
    /* The size is stored in bytes */
    size_t size;                /* bit 0 indicates whether the block is used and */
    /* bit 1 allows to know whether the previous block is free */
    union {
        struct free_ptr_struct free_ptr;
        u8_t buffer[1];         /*sizeof(struct free_ptr_struct)]; */
    } ptr;
} bhdr_t;

/* This structure is embedded at the beginning of each area, giving us
 * enough information to cope with a set of areas */

typedef struct area_info_struct {
    bhdr_t *end;
    struct area_info_struct *next;
} area_info_t;

typedef struct TLSF_struct {
    /* the TLSF's structure signature */
    u32_t tlsf_signature;

#if TLSF_USE_LOCKS
    TLSF_MLOCK_T lock;
#endif

#if TLSF_STATISTIC
    /* These can not be calculated outside tlsf because we
     * do not know the sizes when freeing/reallocing memory. */
    size_t used_size;
    size_t max_size;
#endif

    /* A linked list holding all the existing areas */
    area_info_t *area_head;

    /* the first-level bitmap */
    /* This array should have a size of REAL_FLI bits */
    u32_t fl_bitmap;

    /* the second-level bitmap */
    u32_t sl_bitmap[REAL_FLI];

    bhdr_t *matrix[REAL_FLI][MAX_SLI];
} tlsf_t;


/******************************************************************/
/**************     Helping functions    **************************/
/******************************************************************/
static __inline__ void set_bit(int nr, u32_t * addr);
static __inline__ void clear_bit(int nr, u32_t * addr);
static __inline__ int ls_bit(int x);
static __inline__ int ms_bit(int x);
static __inline__ void MAPPING_SEARCH(size_t * _r, int *_fl, int *_sl);
static __inline__ void MAPPING_INSERT(size_t _r, int *_fl, int *_sl);
static __inline__ bhdr_t *FIND_SUITABLE_BLOCK(tlsf_t * _tlsf, int *_fl, int *_sl);
static __inline__ bhdr_t *process_area(void *area, size_t size);
#if USE_SBRK || USE_MMAP
static __inline__ void *get_new_area(size_t * size);
#endif

static const int table[] = {
    -1, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4,
    4, 4,
    4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5,
    5, 5, 5, 5, 5, 5, 5,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6,
    6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6,
    6, 6, 6, 6, 6, 6, 6,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7,
    7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7,
    7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7,
    7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7,
    7, 7, 7, 7, 7, 7, 7
};

static __inline__ int ls_bit(int i)
{
    unsigned int a;
    unsigned int x = i & -i;

    a = x <= 0xffff ? (x <= 0xff ? 0 : 8) : (x <= 0xffffff ? 16 : 24);
    return table[x >> a] + a;
}

static __inline__ int ms_bit(int i)
{
    unsigned int a;
    unsigned int x = (unsigned int) i;

    a = x <= 0xffff ? (x <= 0xff ? 0 : 8) : (x <= 0xffffff ? 16 : 24);
    return table[x >> a] + a;
}

static __inline__ void set_bit(int nr, u32_t * addr)
{
    addr[nr >> 5] |= 1 << (nr & 0x1f);
}

static __inline__ void clear_bit(int nr, u32_t * addr)
{
    addr[nr >> 5] &= ~(1 << (nr & 0x1f));
}

static __inline__ void MAPPING_SEARCH(size_t * _r, int *_fl, int *_sl)
{
    int _t;

    if (*_r < SMALL_BLOCK) {
        *_fl = 0;
        *_sl = *_r / (SMALL_BLOCK / MAX_SLI);
    } else {
        _t = (1 << (ms_bit(*_r) - MAX_LOG2_SLI)) - 1;
        *_r = *_r + _t;
        *_fl = ms_bit(*_r);
        *_sl = (*_r >> (*_fl - MAX_LOG2_SLI)) - MAX_SLI;
        *_fl -= FLI_OFFSET;
        /*if ((*_fl -= FLI_OFFSET) < 0) // FL wil be always >0!
         *_fl = *_sl = 0;
         */
        *_r &= ~_t;
    }
}

static __inline__ void MAPPING_INSERT(size_t _r, int *_fl, int *_sl)
{
    if (_r < SMALL_BLOCK) {
        *_fl = 0;
        *_sl = _r / (SMALL_BLOCK / MAX_SLI);
    } else {
        *_fl = ms_bit(_r);
        *_sl = (_r >> (*_fl - MAX_LOG2_SLI)) - MAX_SLI;
        *_fl -= FLI_OFFSET;
    }
}


static __inline__ bhdr_t *FIND_SUITABLE_BLOCK(tlsf_t * _tlsf, int *_fl, int *_sl)
{
    u32_t _tmp = _tlsf->sl_bitmap[*_fl] & (~0 << *_sl);
    bhdr_t *_b = NULL;

    if (_tmp) {
        *_sl = ls_bit(_tmp);
        _b = _tlsf->matrix[*_fl][*_sl];
    } else {
        *_fl = ls_bit(_tlsf->fl_bitmap & (~0 << (*_fl + 1)));
        if (*_fl > 0) {         /* likely */
            *_sl = ls_bit(_tlsf->sl_bitmap[*_fl]);
            _b = _tlsf->matrix[*_fl][*_sl];
        }
    }
    return _b;
}


#define EXTRACT_BLOCK_HDR(_b, _tlsf, _fl, _sl) do {          \
    _tlsf -> matrix [_fl] [_sl] = _b -> ptr.free_ptr.next;    \
    if (_tlsf -> matrix[_fl][_sl])                \
      _tlsf -> matrix[_fl][_sl] -> ptr.free_ptr.prev = NULL;  \
    else {                            \
      clear_bit (_sl, &_tlsf -> sl_bitmap [_fl]);        \
      if (!_tlsf -> sl_bitmap [_fl])              \
        clear_bit (_fl, &_tlsf -> fl_bitmap);        \
    }                              \
    _b -> ptr.free_ptr.prev =  NULL;        \
    _b -> ptr.free_ptr.next =  NULL;        \
  }while(0)


#define EXTRACT_BLOCK(_b, _tlsf, _fl, _sl) do {              \
    if (_b -> ptr.free_ptr.next)                  \
      _b -> ptr.free_ptr.next -> ptr.free_ptr.prev = _b -> ptr.free_ptr.prev; \
    if (_b -> ptr.free_ptr.prev)                  \
      _b -> ptr.free_ptr.prev -> ptr.free_ptr.next = _b -> ptr.free_ptr.next; \
    if (_tlsf -> matrix [_fl][_sl] == _b) {              \
      _tlsf -> matrix [_fl][_sl] = _b -> ptr.free_ptr.next;    \
      if (!_tlsf -> matrix [_fl][_sl]) {              \
        clear_bit (_sl, &_tlsf -> sl_bitmap[_fl]);        \
        if (!_tlsf -> sl_bitmap [_fl])              \
          clear_bit (_fl, &_tlsf -> fl_bitmap);        \
      }                              \
    }                                \
    _b -> ptr.free_ptr.prev = NULL;          \
    _b -> ptr.free_ptr.next = NULL;          \
  } while(0)

#define INSERT_BLOCK(_b, _tlsf, _fl, _sl) do {              \
    _b -> ptr.free_ptr.prev = NULL; \
    _b -> ptr.free_ptr.next = _tlsf -> matrix [_fl][_sl]; \
    if (_tlsf -> matrix [_fl][_sl])                  \
      _tlsf -> matrix [_fl][_sl] -> ptr.free_ptr.prev = _b;    \
    _tlsf -> matrix [_fl][_sl] = _b;                \
    set_bit (_sl, &_tlsf -> sl_bitmap [_fl]);            \
    set_bit (_fl, &_tlsf -> fl_bitmap);                \
  } while(0)

#ifndef MAP_ANONYMOUS
#  ifdef MAP_ANON
#    define MAP_ANONYMOUS MAP_ANON
#  else
#    define MAP_ANONYMOUS 0x20
#  endif
#endif

#if USE_SBRK || USE_MMAP
static __inline__ void *get_new_area(size_t * size) 
{
    void *area;

#if USE_SBRK
    area = (void *)sbrk(0);
    if (((void *)sbrk(*size)) != ((void *) -1))
        return area;
#endif

#if USE_MMAP
    *size = ROUNDUP(*size, PAGE_SIZE);
    if ((area = mmap(0, *size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0)) != MAP_FAILED)
        return area;
#endif
    return ((void *) ~0);
}
#endif

static __inline__ bhdr_t *process_area(void *area, size_t size)
{
    bhdr_t *b, *lb, *ib;
    area_info_t *ai;

    ib = (bhdr_t *) area;
    ib->size =
        (sizeof(area_info_t) <
         MIN_BLOCK_SIZE) ? MIN_BLOCK_SIZE : ROUNDUP_SIZE(sizeof(area_info_t)) | USED_BLOCK | PREV_USED;
    b = (bhdr_t *) GET_NEXT_BLOCK(ib->ptr.buffer, ib->size & BLOCK_SIZE);
    b->size = ROUNDDOWN_SIZE(size - 3 * BHDR_OVERHEAD - (ib->size & BLOCK_SIZE)) | USED_BLOCK | PREV_USED;
    b->ptr.free_ptr.prev = b->ptr.free_ptr.next = 0;
    lb = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
    lb->prev_hdr = b;
    lb->size = 0 | USED_BLOCK | PREV_FREE;
    ai = (area_info_t *) ib->ptr.buffer;
    ai->next = 0;
    ai->end = lb;
    return ib;
}

/******************************************************************/
/******************** Begin of the allocator code *****************/
/******************************************************************/

static char *mp = NULL;         /* Default memory pool. */

/******************************************************************/
size_t init_memory_pool(size_t mem_pool_size, void *mem_pool)
{
/******************************************************************/
    tlsf_t *tlsf;
    bhdr_t *b, *ib;

    if (!mem_pool || !mem_pool_size || mem_pool_size < sizeof(tlsf_t) + BHDR_OVERHEAD * 8) {
        ERROR_MSG("init_memory_pool (): memory_pool invalid\n");
        return -1;
    }

    if (((unsigned long) mem_pool & PTR_MASK)) {
        ERROR_MSG("init_memory_pool (): mem_pool must be aligned to a word\n");
        return -1;
    }
    tlsf = (tlsf_t *) mem_pool;
    /* Check if already initialised */
    if (tlsf->tlsf_signature == TLSF_SIGNATURE) {
        mp = mem_pool;
        b = GET_NEXT_BLOCK(mp, ROUNDUP_SIZE(sizeof(tlsf_t)));
        return b->size & BLOCK_SIZE;
    }

    mp = mem_pool;

    /* Zeroing the memory pool */
    memset(mem_pool, 0, sizeof(tlsf_t));

    tlsf->tlsf_signature = TLSF_SIGNATURE;

    TLSF_CREATE_LOCK(&tlsf->lock);

    ib = process_area(GET_NEXT_BLOCK
                      (mem_pool, ROUNDUP_SIZE(sizeof(tlsf_t))), ROUNDDOWN_SIZE(mem_pool_size - sizeof(tlsf_t)));
    b = GET_NEXT_BLOCK(ib->ptr.buffer, ib->size & BLOCK_SIZE);
    free_ex(b->ptr.buffer, tlsf);
    tlsf->area_head = (area_info_t *) ib->ptr.buffer;

#if TLSF_STATISTIC
    tlsf->used_size = mem_pool_size - (b->size & BLOCK_SIZE);
    tlsf->max_size = tlsf->used_size;
#endif

    return (b->size & BLOCK_SIZE);
}

/******************************************************************/
size_t add_new_area(void *area, size_t area_size, void *mem_pool)
{
/******************************************************************/
    tlsf_t *tlsf = (tlsf_t *) mem_pool;
    area_info_t *ptr, *ptr_prev, *ai;
    bhdr_t *ib0, *b0, *lb0, *ib1, *b1, *lb1, *next_b;

    memset(area, 0, area_size);
    ptr = tlsf->area_head;
    ptr_prev = 0;

    ib0 = process_area(area, area_size);
    b0 = GET_NEXT_BLOCK(ib0->ptr.buffer, ib0->size & BLOCK_SIZE);
    lb0 = GET_NEXT_BLOCK(b0->ptr.buffer, b0->size & BLOCK_SIZE);

    /* Before inserting the new area, we have to merge this area with the
       already existing ones */

    while (ptr) {
        ib1 = (bhdr_t *) ((char *) ptr - BHDR_OVERHEAD);
        b1 = GET_NEXT_BLOCK(ib1->ptr.buffer, ib1->size & BLOCK_SIZE);
        lb1 = ptr->end;

        /* Merging the new area with the next physically contigous one */
        if ((unsigned long) ib1 == (unsigned long) lb0 + BHDR_OVERHEAD) {
            if (tlsf->area_head == ptr) {
                tlsf->area_head = ptr->next;
                ptr = ptr->next;
            } else {
                ptr_prev->next = ptr->next;
                ptr = ptr->next;
            }

            b0->size =
                ROUNDDOWN_SIZE((b0->size & BLOCK_SIZE) +
                               (ib1->size & BLOCK_SIZE) + 2 * BHDR_OVERHEAD) | USED_BLOCK | PREV_USED;

            b1->prev_hdr = b0;
            lb0 = lb1;

            continue;
        }

        /* Merging the new area with the previous physically contigous
           one */
        if ((unsigned long) lb1->ptr.buffer == (unsigned long) ib0) {
            if (tlsf->area_head == ptr) {
                tlsf->area_head = ptr->next;
                ptr = ptr->next;
            } else {
                ptr_prev->next = ptr->next;
                ptr = ptr->next;
            }

            lb1->size =
                ROUNDDOWN_SIZE((b0->size & BLOCK_SIZE) +
                               (ib0->size & BLOCK_SIZE) + 2 * BHDR_OVERHEAD) | USED_BLOCK | (lb1->size & PREV_STATE);
            next_b = GET_NEXT_BLOCK(lb1->ptr.buffer, lb1->size & BLOCK_SIZE);
            next_b->prev_hdr = lb1;
            b0 = lb1;
            ib0 = ib1;

            continue;
        }
        ptr_prev = ptr;
        ptr = ptr->next;
    }

    /* Inserting the area in the list of linked areas */
    ai = (area_info_t *) ib0->ptr.buffer;
    ai->next = tlsf->area_head;
    ai->end = lb0;
    tlsf->area_head = ai;
    free_ex(b0->ptr.buffer, mem_pool);
    return (b0->size & BLOCK_SIZE);
}


/******************************************************************/
size_t get_used_size(void *mem_pool)
{
/******************************************************************/
#if TLSF_STATISTIC
    return ((tlsf_t *) mem_pool)->used_size;
#else
    return 0;
#endif
}

/******************************************************************/
size_t get_max_size(void *mem_pool)
{
/******************************************************************/
#if TLSF_STATISTIC
    return ((tlsf_t *) mem_pool)->max_size;
#else
    return 0;
#endif
}

/******************************************************************/
void destroy_memory_pool(void *mem_pool)
{
/******************************************************************/
    tlsf_t *tlsf = (tlsf_t *) mem_pool;

    tlsf->tlsf_signature = 0;

    TLSF_DESTROY_LOCK(&tlsf->lock);

}


/******************************************************************/
void *tlsf_malloc(size_t size)
{
/******************************************************************/
    void *ret;

#if USE_MMAP || USE_SBRK
    if (!mp) {
        size_t area_size;
        void *area;

        area_size = sizeof(tlsf_t) + BHDR_OVERHEAD * 8; /* Just a safety constant */
        area_size = (area_size > DEFAULT_AREA_SIZE) ? area_size : DEFAULT_AREA_SIZE;
        area = get_new_area(&area_size);
        if (area == ((void *) ~0))
            return NULL;        /* Not enough system memory */
        init_memory_pool(area_size, area);
    }
#endif

    TLSF_ACQUIRE_LOCK(&((tlsf_t *)mp)->lock);

    ret = malloc_ex(size, mp);

    TLSF_RELEASE_LOCK(&((tlsf_t *)mp)->lock);

    return ret;
}

/******************************************************************/
void tlsf_free(void *ptr)
{
/******************************************************************/

    TLSF_ACQUIRE_LOCK(&((tlsf_t *)mp)->lock);

    free_ex(ptr, mp);

    TLSF_RELEASE_LOCK(&((tlsf_t *)mp)->lock);

}

/******************************************************************/
void *tlsf_realloc(void *ptr, size_t size)
{
/******************************************************************/
    void *ret;

#if USE_MMAP || USE_SBRK
  if (!mp) {
    return tlsf_malloc(size);
  }
#endif

    TLSF_ACQUIRE_LOCK(&((tlsf_t *)mp)->lock);

    ret = realloc_ex(ptr, size, mp);

    TLSF_RELEASE_LOCK(&((tlsf_t *)mp)->lock);

    return ret;
}

/******************************************************************/
void *tlsf_calloc(size_t nelem, size_t elem_size)
{
/******************************************************************/
    void *ret;

    TLSF_ACQUIRE_LOCK(&((tlsf_t *)mp)->lock);

    ret = calloc_ex(nelem, elem_size, mp);

    TLSF_RELEASE_LOCK(&((tlsf_t *)mp)->lock);

    return ret;
}

/******************************************************************/
void *malloc_ex(size_t size, void *mem_pool)
{
/******************************************************************/
    tlsf_t *tlsf = (tlsf_t *) mem_pool;
    bhdr_t *b, *b2, *next_b;
    int fl, sl;
    size_t tmp_size;

    size = (size < MIN_BLOCK_SIZE) ? MIN_BLOCK_SIZE : ROUNDUP_SIZE(size);

    /* Rounding up the requested size and calculating fl and sl */
    MAPPING_SEARCH(&size, &fl, &sl);

    /* Searching a free block, recall that this function changes the values of fl and sl,
       so they are not longer valid when the function fails */
    b = FIND_SUITABLE_BLOCK(tlsf, &fl, &sl);
#if USE_MMAP || USE_SBRK
    if (!b) {
        size_t area_size;
        void *area;
        /* Growing the pool size when needed */
        area_size = size + BHDR_OVERHEAD * 8;   /* size plus enough room for the requered headers. */
        area_size = (area_size > DEFAULT_AREA_SIZE) ? area_size : DEFAULT_AREA_SIZE;
        area = get_new_area(&area_size);        /* Call sbrk or mmap */
        if (area == ((void *) ~0))
            return NULL;        /* Not enough system memory */
        add_new_area(area, area_size, mem_pool);
        /* Rounding up the requested size and calculating fl and sl */
        MAPPING_SEARCH(&size, &fl, &sl);
        /* Searching a free block */
        b = FIND_SUITABLE_BLOCK(tlsf, &fl, &sl);
    }
#endif
    if (!b)
        return NULL;            /* Not found */

    EXTRACT_BLOCK_HDR(b, tlsf, fl, sl);

    /*-- found: */
    next_b = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
    /* Should the block be split? */
    tmp_size = (b->size & BLOCK_SIZE) - size;
    if (tmp_size >= sizeof(bhdr_t)) {
        tmp_size -= BHDR_OVERHEAD;
        b2 = GET_NEXT_BLOCK(b->ptr.buffer, size);
        b2->size = tmp_size | FREE_BLOCK | PREV_USED;
        next_b->prev_hdr = b2;
        MAPPING_INSERT(tmp_size, &fl, &sl);
        INSERT_BLOCK(b2, tlsf, fl, sl);

        b->size = size | (b->size & PREV_STATE);
    } else {
        next_b->size &= (~PREV_FREE);
        b->size &= (~FREE_BLOCK);       /* Now it's used */
    }

    TLSF_ADD_SIZE(tlsf, b);

    return (void *) b->ptr.buffer;
}

extern void free_ex(void *ptr, void *mem_pool) {
    tlsf_t *tlsf = (tlsf_t *) mem_pool;
    bhdr_t *b, *tmp_b;
    int fl = 0, sl = 0;

    if (!ptr) {
        return;
    }
    b = (bhdr_t *) ((char *) ptr - BHDR_OVERHEAD);
    b->size |= FREE_BLOCK;

    TLSF_REMOVE_SIZE(tlsf, b);

    b->ptr.free_ptr.prev = NULL;
    b->ptr.free_ptr.next = NULL;
    tmp_b = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
    if (tmp_b->size & FREE_BLOCK) {
        MAPPING_INSERT(tmp_b->size & BLOCK_SIZE, &fl, &sl);
        EXTRACT_BLOCK(tmp_b, tlsf, fl, sl);
        b->size += (tmp_b->size & BLOCK_SIZE) + BHDR_OVERHEAD;
    }
    if (b->size & PREV_FREE) {
        tmp_b = b->prev_hdr;
        MAPPING_INSERT(tmp_b->size & BLOCK_SIZE, &fl, &sl);
        EXTRACT_BLOCK(tmp_b, tlsf, fl, sl);
        tmp_b->size += (b->size & BLOCK_SIZE) + BHDR_OVERHEAD;
        b = tmp_b;
    }
    MAPPING_INSERT(b->size & BLOCK_SIZE, &fl, &sl);
    INSERT_BLOCK(b, tlsf, fl, sl);

    tmp_b = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
    tmp_b->size |= PREV_FREE;
    tmp_b->prev_hdr = b;
}

/******************************************************************/
void *realloc_ex(void *ptr, size_t new_size, void *mem_pool)
{
/******************************************************************/
    tlsf_t *tlsf = (tlsf_t *) mem_pool;
    void *ptr_aux;
    unsigned int cpsize;
    bhdr_t *b, *tmp_b, *next_b;
    int fl, sl;
    size_t tmp_size;

    if (!ptr) {
        if (new_size)
            return (void *) malloc_ex(new_size, mem_pool);
        if (!new_size)
            return NULL;
    } else if (!new_size) {
        free_ex(ptr, mem_pool);
        return NULL;
    }

    b = (bhdr_t *) ((char *) ptr - BHDR_OVERHEAD);
    next_b = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
    new_size = (new_size < MIN_BLOCK_SIZE) ? MIN_BLOCK_SIZE : ROUNDUP_SIZE(new_size);
    tmp_size = (b->size & BLOCK_SIZE);
    if (new_size <= tmp_size) {
        TLSF_REMOVE_SIZE(tlsf, b);
        if (next_b->size & FREE_BLOCK) {
            MAPPING_INSERT(next_b->size & BLOCK_SIZE, &fl, &sl);
            EXTRACT_BLOCK(next_b, tlsf, fl, sl);
            tmp_size += (next_b->size & BLOCK_SIZE) + BHDR_OVERHEAD;
            next_b = GET_NEXT_BLOCK(next_b->ptr.buffer, next_b->size & BLOCK_SIZE);
            /* We allways reenter this free block because tmp_size will
               be greater then sizeof (bhdr_t) */
        }
        tmp_size -= new_size;
        if (tmp_size >= sizeof(bhdr_t)) {
            tmp_size -= BHDR_OVERHEAD;
            tmp_b = GET_NEXT_BLOCK(b->ptr.buffer, new_size);
            tmp_b->size = tmp_size | FREE_BLOCK | PREV_USED;
            next_b->prev_hdr = tmp_b;
            next_b->size |= PREV_FREE;
            MAPPING_INSERT(tmp_size, &fl, &sl);
            INSERT_BLOCK(tmp_b, tlsf, fl, sl);
            b->size = new_size | (b->size & PREV_STATE);
        }
        TLSF_ADD_SIZE(tlsf, b);
        return (void *) b->ptr.buffer;
    }
    if ((next_b->size & FREE_BLOCK)) {
        if (new_size <= (tmp_size + (next_b->size & BLOCK_SIZE))) {
            TLSF_REMOVE_SIZE(tlsf, b);
            MAPPING_INSERT(next_b->size & BLOCK_SIZE, &fl, &sl);
            EXTRACT_BLOCK(next_b, tlsf, fl, sl);
            b->size += (next_b->size & BLOCK_SIZE) + BHDR_OVERHEAD;
            next_b = GET_NEXT_BLOCK(b->ptr.buffer, b->size & BLOCK_SIZE);
            next_b->prev_hdr = b;
            next_b->size &= ~PREV_FREE;
            tmp_size = (b->size & BLOCK_SIZE) - new_size;
            if (tmp_size >= sizeof(bhdr_t)) {
                tmp_size -= BHDR_OVERHEAD;
                tmp_b = GET_NEXT_BLOCK(b->ptr.buffer, new_size);
                tmp_b->size = tmp_size | FREE_BLOCK | PREV_USED;
                next_b->prev_hdr = tmp_b;
                next_b->size |= PREV_FREE;
                MAPPING_INSERT(tmp_size, &fl, &sl);
                INSERT_BLOCK(tmp_b, tlsf, fl, sl);
                b->size = new_size | (b->size & PREV_STATE);
            }
            TLSF_ADD_SIZE(tlsf, b);
            return (void *) b->ptr.buffer;
        }
    }

    ptr_aux = malloc_ex(new_size, mem_pool);

    cpsize = ((b->size & BLOCK_SIZE) > new_size) ? new_size : (b->size & BLOCK_SIZE);

    memcpy(ptr_aux, ptr, cpsize);

    free_ex(ptr, mem_pool);
    return ptr_aux;
}


/******************************************************************/
void *calloc_ex(size_t nelem, size_t elem_size, void *mem_pool)
{
/******************************************************************/
    void *ptr;

    if (nelem <= 0 || elem_size <= 0)
        return NULL;

    if (!(ptr = malloc_ex(nelem * elem_size, mem_pool)))
        return NULL;
    memset(ptr, 0, nelem * elem_size);

    return ptr;
}

/* for Nimrod: */
size_t TLSF_GET_USED_SIZE(void) { return (((tlsf_t *)mp)->used_size); }
size_t TLSF_GET_MAX_SIZE(void) { return (((tlsf_t *)mp)->max_size); }


#if _DEBUG_TLSF_

/***************  DEBUG FUNCTIONS   **************/

/* The following functions have been designed to ease the debugging of */
/* the TLSF  structure.  For non-developing  purposes, it may  be they */
/* haven't too much worth.  To enable them, _DEBUG_TLSF_ must be set.  */

extern void dump_memory_region(unsigned char *mem_ptr, unsigned int size);
extern void print_block(bhdr_t * b);
extern void print_tlsf(tlsf_t * tlsf);
void print_all_blocks(tlsf_t * tlsf);

void dump_memory_region(unsigned char *mem_ptr, unsigned int size)
{

    unsigned long begin = (unsigned long) mem_ptr;
    unsigned long end = (unsigned long) mem_ptr + size;
    int column = 0;

    begin >>= 2;
    begin <<= 2;

    end >>= 2;
    end++;
    end <<= 2;

    PRINT_MSG("\nMemory region dumped: 0x%lx - 0x%lx\n\n", begin, end);

    column = 0;
    PRINT_MSG("0x%lx ", begin);

    while (begin < end) {
        if (((unsigned char *) begin)[0] == 0)
            PRINT_MSG("00");
        else
            PRINT_MSG("%02x", ((unsigned char *) begin)[0]);
        if (((unsigned char *) begin)[1] == 0)
            PRINT_MSG("00 ");
        else
            PRINT_MSG("%02x ", ((unsigned char *) begin)[1]);
        begin += 2;
        column++;
        if (column == 8) {
            PRINT_MSG("\n0x%lx ", begin);
            column = 0;
        }

    }
    PRINT_MSG("\n\n");
}

void print_block(bhdr_t * b)
{
    if (!b)
        return;
    PRINT_MSG(">> [%p] (", b);
    if ((b->size & BLOCK_SIZE))
        PRINT_MSG("%lu bytes, ", (unsigned long) (b->size & BLOCK_SIZE));
    else
        PRINT_MSG("sentinel, ");
    if ((b->size & BLOCK_STATE) == FREE_BLOCK)
        PRINT_MSG("free [%p, %p], ", b->ptr.free_ptr.prev, b->ptr.free_ptr.next);
    else
        PRINT_MSG("used, ");
    if ((b->size & PREV_STATE) == PREV_FREE)
        PRINT_MSG("prev. free [%p])\n", b->prev_hdr);
    else
        PRINT_MSG("prev used)\n");
}

void print_tlsf(tlsf_t * tlsf)
{
    bhdr_t *next;
    int i, j;

    PRINT_MSG("\nTLSF at %p\n", tlsf);

    PRINT_MSG("FL bitmap: 0x%x\n\n", (unsigned) tlsf->fl_bitmap);

    for (i = 0; i < REAL_FLI; i++) {
        if (tlsf->sl_bitmap[i])
            PRINT_MSG("SL bitmap 0x%x\n", (unsigned) tlsf->sl_bitmap[i]);
        for (j = 0; j < MAX_SLI; j++) {
            next = tlsf->matrix[i][j];
            if (next)
                PRINT_MSG("-> [%d][%d]\n", i, j);
            while (next) {
                print_block(next);
                next = next->ptr.free_ptr.next;
            }
        }
    }
}

void print_all_blocks(tlsf_t * tlsf)
{
    area_info_t *ai;
    bhdr_t *next;
    PRINT_MSG("\nTLSF at %p\nALL BLOCKS\n\n", tlsf);
    ai = tlsf->area_head;
    while (ai) {
        next = (bhdr_t *) ((char *) ai - BHDR_OVERHEAD);
        while (next) {
            print_block(next);
            if ((next->size & BLOCK_SIZE))
                next = GET_NEXT_BLOCK(next->ptr.buffer, next->size & BLOCK_SIZE);
            else
                next = NULL;
        }
        ai = ai->next;
    }
}

#endif
