/*
 * Copyright (c) 2003, 2007 Matteo Frigo
 * Copyright (c) 2003, 2007 Massachusetts Institute of Technology
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */


/* machine-dependent cycle counters code. Needs to be inlined. */

/***************************************************************************/
/* To use the cycle counters in your code, simply #include "cycle.h" (this
   file), and then use the functions/macros:

                 ticks getticks(void);

   ticks is an opaque typedef defined below, representing the current time.
   You extract the elapsed time between two calls to gettick() via:

                 double elapsed(ticks t1, ticks t0);

   which returns a double-precision variable in arbitrary units.  You
   are not expected to convert this into human units like seconds; it
   is intended only for *comparisons* of time intervals.

   (In order to use some of the OS-dependent timer routines like
   Solaris' gethrtime, you need to paste the autoconf snippet below
   into your configure.ac file and #include "config.h" before cycle.h,
   or define the relevant macros manually if you are not using autoconf.)
*/

/***************************************************************************/
/* This file uses macros like HAVE_GETHRTIME that are assumed to be
   defined according to whether the corresponding function/type/header
   is available on your system.  The necessary macros are most
   conveniently defined if you are using GNU autoconf, via the tests:
   
   dnl ---------------------------------------------------------------------

   AC_C_INLINE
   AC_HEADER_TIME
   AC_CHECK_HEADERS([sys/time.h c_asm.h intrinsics.h mach/mach_time.h])

   AC_CHECK_TYPE([hrtime_t],[AC_DEFINE(HAVE_HRTIME_T, 1, [Define to 1 if hrtime_t is defined in <sys/time.h>])],,[#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif])

   AC_CHECK_FUNCS([gethrtime read_real_time time_base_to_time clock_gettime mach_absolute_time])

   dnl Cray UNICOS _rtc() (real-time clock) intrinsic
   AC_MSG_CHECKING([for _rtc intrinsic])
   rtc_ok=yes
   AC_TRY_LINK([#ifdef HAVE_INTRINSICS_H
#include <intrinsics.h>
#endif], [_rtc()], [AC_DEFINE(HAVE__RTC,1,[Define if you have the UNICOS _rtc() intrinsic.])], [rtc_ok=no])
   AC_MSG_RESULT($rtc_ok)

   dnl ---------------------------------------------------------------------
*/

/***************************************************************************/

#if TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif

#define INLINE_ELAPSED(INL) static INL double elapsed(ticks t1, ticks t0) \
{									  \
     return (double)t1 - (double)t0;					  \
}

/*----------------------------------------------------------------*/
/* Solaris */
#if defined(HAVE_GETHRTIME) && defined(HAVE_HRTIME_T) && !defined(HAVE_TICK_COUNTER)
typedef hrtime_t ticks;

#define getticks gethrtime

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/* AIX v. 4+ routines to read the real-time clock or time-base register */
#if defined(HAVE_READ_REAL_TIME) && defined(HAVE_TIME_BASE_TO_TIME) && !defined(HAVE_TICK_COUNTER)
typedef timebasestruct_t ticks;

static __inline ticks getticks(void)
{
     ticks t;
     read_real_time(&t, TIMEBASE_SZ);
     return t;
}

static __inline double elapsed(ticks t1, ticks t0) /* time in nanoseconds */
{
     time_base_to_time(&t1, TIMEBASE_SZ);
     time_base_to_time(&t0, TIMEBASE_SZ);
     return (((double)t1.tb_high - (double)t0.tb_high) * 1.0e9 + 
	     ((double)t1.tb_low - (double)t0.tb_low));
}

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/*
 * PowerPC ``cycle'' counter using the time base register.
 */
#if ((((defined(__GNUC__) && (defined(__powerpc__) || defined(__ppc__))) || (defined(__MWERKS__) && defined(macintosh)))) || (defined(__IBM_GCC_ASM) && (defined(__powerpc__) || defined(__ppc__))))  && !defined(HAVE_TICK_COUNTER)
typedef unsigned long long ticks;

static __inline__ ticks getticks(void)
{
     unsigned int tbl, tbu0, tbu1;

     do {
	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu0));
	  __asm__ __volatile__ ("mftb %0" : "=r"(tbl));
	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu1));
     } while (tbu0 != tbu1);

     return (((unsigned long long)tbu0) << 32) | tbl;
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif

/* MacOS/Mach (Darwin) time-base register interface (unlike UpTime,
   from Carbon, requires no additional libraries to be linked). */
#if defined(HAVE_MACH_ABSOLUTE_TIME) && defined(HAVE_MACH_MACH_TIME_H) && !defined(HAVE_TICK_COUNTER)
#include <mach/mach_time.h>
typedef uint64_t ticks;
#define getticks mach_absolute_time
INLINE_ELAPSED(__inline__)
#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/*
 * Pentium cycle counter 
 */
#if (defined(__GNUC__) || defined(__ICC)) && defined(__i386__)  && !defined(HAVE_TICK_COUNTER)
typedef unsigned long long ticks;

static __inline__ ticks getticks(void)
{
     ticks ret;

     __asm__ __volatile__("rdtsc": "=A" (ret));
     /* no input, nothing else clobbered */
     return ret;
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#define TIME_MIN 5000.0   /* unreliable pentium IV cycle counter */
#endif

/* Visual C++ -- thanks to Morten Nissov for his help with this */
#if _MSC_VER >= 1200 && _M_IX86 >= 500 && !defined(HAVE_TICK_COUNTER)
#include <windows.h>
typedef LARGE_INTEGER ticks;
#define RDTSC __asm __emit 0fh __asm __emit 031h /* hack for VC++ 5.0 */

static __inline ticks getticks(void)
{
     ticks retval;

     __asm {
	  RDTSC
	  mov retval.HighPart, edx
	  mov retval.LowPart, eax
     }
     return retval;
}

static __inline double elapsed(ticks t1, ticks t0)
{  
     return (double)t1.QuadPart - (double)t0.QuadPart;
}  

#define HAVE_TICK_COUNTER
#define TIME_MIN 5000.0   /* unreliable pentium IV cycle counter */
#endif

/*----------------------------------------------------------------*/
/*
 * X86-64 cycle counter
 */
#if (defined(__GNUC__) || defined(__ICC) || defined(__SUNPRO_C)) && defined(__x86_64__)  && !defined(HAVE_TICK_COUNTER)
typedef unsigned long long ticks;

static __inline__ ticks getticks(void)
{
     unsigned a, d; 
     asm volatile("rdtsc" : "=a" (a), "=d" (d)); 
     return ((ticks)a) | (((ticks)d) << 32); 
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif

/* PGI compiler, courtesy Cristiano Calonaci, Andrea Tarsi, & Roberto Gori.
   NOTE: this code will fail to link unless you use the -Masmkeyword compiler
   option (grrr). */
#if defined(__PGI) && defined(__x86_64__) && !defined(HAVE_TICK_COUNTER) 
typedef unsigned long long ticks;
static ticks getticks(void)
{
    asm(" rdtsc; shl    $0x20,%rdx; mov    %eax,%eax; or     %rdx,%rax;    ");
}
INLINE_ELAPSED(__inline__)
#define HAVE_TICK_COUNTER
#endif

/* Visual C++, courtesy of Dirk Michaelis */
#if _MSC_VER >= 1400 && (defined(_M_AMD64) || defined(_M_X64)) && !defined(HAVE_TICK_COUNTER)

#include <intrin.h>
#pragma intrinsic(__rdtsc)
typedef unsigned __int64 ticks;
#define getticks __rdtsc
INLINE_ELAPSED(__inline)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/*
 * IA64 cycle counter
 */

/* intel's icc/ecc compiler */
#if (defined(__EDG_VERSION) || defined(__ECC)) && defined(__ia64__) && !defined(HAVE_TICK_COUNTER)
typedef unsigned long ticks;
#include <ia64intrin.h>

static __inline__ ticks getticks(void)
{
     return __getReg(_IA64_REG_AR_ITC);
}
 
INLINE_ELAPSED(__inline__)
 
#define HAVE_TICK_COUNTER
#endif

/* gcc */
#if defined(__GNUC__) && defined(__ia64__) && !defined(HAVE_TICK_COUNTER)
typedef unsigned long ticks;

static __inline__ ticks getticks(void)
{
     ticks ret;

     __asm__ __volatile__ ("mov %0=ar.itc" : "=r"(ret));
     return ret;
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif

/* HP/UX IA64 compiler, courtesy Teresa L. Johnson: */
#if defined(__hpux) && defined(__ia64) && !defined(HAVE_TICK_COUNTER)
#include <machine/sys/inline.h>
typedef unsigned long ticks;

static inline ticks getticks(void)
{
     ticks ret;

     ret = _Asm_mov_from_ar (_AREG_ITC);
     return ret;
}

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif

/* Microsoft Visual C++ */
#if defined(_MSC_VER) && defined(_M_IA64) && !defined(HAVE_TICK_COUNTER)
typedef unsigned __int64 ticks;

#  ifdef __cplusplus
extern "C"
#  endif
ticks __getReg(int whichReg);
#pragma intrinsic(__getReg)

static __inline ticks getticks(void)
{
     volatile ticks temp;
     temp = __getReg(3116);
     return temp;
}

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/*
 * PA-RISC cycle counter 
 */
#if defined(__hppa__) || defined(__hppa) && !defined(HAVE_TICK_COUNTER)
typedef unsigned long ticks;

#  ifdef __GNUC__
static __inline__ ticks getticks(void)
{
     ticks ret;

     __asm__ __volatile__("mfctl 16, %0": "=r" (ret));
     /* no input, nothing else clobbered */
     return ret;
}
#  else
#  include <machine/inline.h>
static inline unsigned long getticks(void)
{
     register ticks ret;
     _MFCTL(16, ret);
     return ret;
}
#  endif

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/* S390, courtesy of James Treacy */
#if defined(__GNUC__) && defined(__s390__) && !defined(HAVE_TICK_COUNTER)
typedef unsigned long long ticks;

static __inline__ ticks getticks(void)
{
     ticks cycles;
     __asm__("stck 0(%0)" : : "a" (&(cycles)) : "memory", "cc");
     return cycles;
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif
/*----------------------------------------------------------------*/
#if defined(__GNUC__) && defined(__alpha__) && !defined(HAVE_TICK_COUNTER)
/*
 * The 32-bit cycle counter on alpha overflows pretty quickly, 
 * unfortunately.  A 1GHz machine overflows in 4 seconds.
 */
typedef unsigned int ticks;

static __inline__ ticks getticks(void)
{
     unsigned long cc;
     __asm__ __volatile__ ("rpcc %0" : "=r"(cc));
     return (cc & 0xFFFFFFFF);
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
#if defined(__GNUC__) && defined(__sparc_v9__) && !defined(HAVE_TICK_COUNTER)
typedef unsigned long ticks;

static __inline__ ticks getticks(void)
{
     ticks ret;
     __asm__ __volatile__("rd %%tick, %0" : "=r" (ret));
     return ret;
}

INLINE_ELAPSED(__inline__)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
#if (defined(__DECC) || defined(__DECCXX)) && defined(__alpha) && defined(HAVE_C_ASM_H) && !defined(HAVE_TICK_COUNTER)
#  include <c_asm.h>
typedef unsigned int ticks;

static __inline ticks getticks(void)
{
     unsigned long cc;
     cc = asm("rpcc %v0");
     return (cc & 0xFFFFFFFF);
}

INLINE_ELAPSED(__inline)

#define HAVE_TICK_COUNTER
#endif
/*----------------------------------------------------------------*/
/* SGI/Irix */
#if defined(HAVE_CLOCK_GETTIME) && defined(CLOCK_SGI_CYCLE) && !defined(HAVE_TICK_COUNTER)
typedef struct timespec ticks;

static inline ticks getticks(void)
{
     struct timespec t;
     clock_gettime(CLOCK_SGI_CYCLE, &t);
     return t;
}

static inline double elapsed(ticks t1, ticks t0)
{
     return ((double)t1.tv_sec - (double)t0.tv_sec) * 1.0E9 +
	  ((double)t1.tv_nsec - (double)t0.tv_nsec);
}
#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/* Cray UNICOS _rtc() intrinsic function */
#if defined(HAVE__RTC) && !defined(HAVE_TICK_COUNTER)
#ifdef HAVE_INTRINSICS_H
#  include <intrinsics.h>
#endif

typedef long long ticks;

#define getticks _rtc

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif

/*----------------------------------------------------------------*/
/* MIPS ZBus */
#if HAVE_MIPS_ZBUS_TIMER
#if defined(__mips__) && !defined(HAVE_TICK_COUNTER)
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>

typedef uint64_t ticks;

static inline ticks getticks(void)
{
  static uint64_t* addr = 0;

  if (addr == 0)
  {
    uint32_t rq_addr = 0x10030000;
    int fd;
    int pgsize;

    pgsize = getpagesize();
    fd = open ("/dev/mem", O_RDONLY | O_SYNC, 0);
    if (fd < 0) {
      perror("open");
      return NULL;
    }
    addr = mmap(0, pgsize, PROT_READ, MAP_SHARED, fd, rq_addr);
    close(fd);
    if (addr == (uint64_t *)-1) {
      perror("mmap");
      return NULL;
    }
  }

  return *addr;
}

INLINE_ELAPSED(inline)

#define HAVE_TICK_COUNTER
#endif
#endif /* HAVE_MIPS_ZBUS_TIMER */

