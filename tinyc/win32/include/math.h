/* 
 * math.h
 *
 * Mathematical functions.
 *
 * This file is part of the Mingw32 package.
 *
 * Contributors:
 *  Created by Colin Peters <colin@bird.fu.is.saga-u.ac.jp>
 *
 *  THIS SOFTWARE IS NOT COPYRIGHTED
 *
 *  This source code is offered for use in the public domain. You may
 *  use, modify or distribute it freely.
 *
 *  This code is distributed in the hope that it will be useful but
 *  WITHOUT ANY WARRANTY. ALL WARRANTIES, EXPRESS OR IMPLIED ARE HEREBY
 *  DISCLAIMED. This includes but is not limited to warranties of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * $Revision: 1.2 $
 * $Author: bellard $
 * $Date: 2005/04/17 13:14:29 $
 *
 */

#ifndef _MATH_H_
#define _MATH_H_

/* All the headers include this file. */
#include <_mingw.h>

/*
 * Types for the _exception structure.
 */

#define	_DOMAIN		1	/* domain error in argument */
#define	_SING		2	/* singularity */
#define	_OVERFLOW	3	/* range overflow */
#define	_UNDERFLOW	4	/* range underflow */
#define	_TLOSS		5	/* total loss of precision */
#define	_PLOSS		6	/* partial loss of precision */

/*
 * Exception types with non-ANSI names for compatibility.
 */

#ifndef	__STRICT_ANSI__
#ifndef	_NO_OLDNAMES

#define	DOMAIN		_DOMAIN
#define	SING		_SING
#define	OVERFLOW	_OVERFLOW
#define	UNDERFLOW	_UNDERFLOW
#define	TLOSS		_TLOSS
#define	PLOSS		_PLOSS

#endif	/* Not _NO_OLDNAMES */
#endif	/* Not __STRICT_ANSI__ */


/* These are also defined in Mingw float.h; needed here as well to work 
   around GCC build issues.  */
#ifndef	__STRICT_ANSI__
#ifndef __MINGW_FPCLASS_DEFINED
#define __MINGW_FPCLASS_DEFINED 1
/* IEEE 754 classication */
#define	_FPCLASS_SNAN	0x0001	/* Signaling "Not a Number" */
#define	_FPCLASS_QNAN	0x0002	/* Quiet "Not a Number" */
#define	_FPCLASS_NINF	0x0004	/* Negative Infinity */
#define	_FPCLASS_NN	0x0008	/* Negative Normal */
#define	_FPCLASS_ND	0x0010	/* Negative Denormal */
#define	_FPCLASS_NZ	0x0020	/* Negative Zero */
#define	_FPCLASS_PZ	0x0040	/* Positive Zero */
#define	_FPCLASS_PD	0x0080	/* Positive Denormal */
#define	_FPCLASS_PN	0x0100	/* Positive Normal */
#define	_FPCLASS_PINF	0x0200	/* Positive Infinity */
#endif /* __MINGW_FPCLASS_DEFINED */
#endif	/* Not __STRICT_ANSI__ */

#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

/*
 * HUGE_VAL is returned by strtod when the value would overflow the
 * representation of 'double'. There are other uses as well.
 *
 * __imp__HUGE is a pointer to the actual variable _HUGE in
 * MSVCRT.DLL. If we used _HUGE directly we would get a pointer
 * to a thunk function.
 *
 * NOTE: The CRTDLL version uses _HUGE_dll instead.
 */

#ifndef __DECLSPEC_SUPPORTED

#ifdef __MSVCRT__
extern double*	__imp__HUGE;
#define	HUGE_VAL	(*__imp__HUGE)
#else
/* CRTDLL */
extern double*	__imp__HUGE_dll;
#define	HUGE_VAL	(*__imp__HUGE_dll)
#endif

#else /* __DECLSPEC_SUPPORTED */

#ifdef __MSVCRT__
__MINGW_IMPORT double	_HUGE;
#define	HUGE_VAL	_HUGE
#else
/* CRTDLL */
__MINGW_IMPORT double	_HUGE_dll;
#define	HUGE_VAL	_HUGE_dll
#endif

#endif /* __DECLSPEC_SUPPORTED */

struct _exception
{
	int	type;
	char	*name;
	double	arg1;
	double	arg2;
	double	retval;
};


double	sin (double);
double	cos (double);
double	tan (double);
double	sinh (double);
double	cosh (double);
double	tanh (double);
double	asin (double);
double	acos (double);
double	atan (double);
double	atan2 (double, double);
double	exp (double);
double	log (double);
double	log10 (double);
double	pow (double, double);
double	sqrt (double);
double	ceil (double);
double	floor (double);
double	fabs (double);
double	ldexp (double, int);
double	frexp (double, int*);
double	modf (double, double*);
double	fmod (double, double);


#ifndef	__STRICT_ANSI__

/* Complex number (for cabs) */
struct _complex
{
	double	x;	/* Real part */
	double	y;	/* Imaginary part */
};

double	_cabs (struct _complex);
double	_hypot (double, double);
double	_j0 (double);
double	_j1 (double);
double	_jn (int, double);
double	_y0 (double);
double	_y1 (double);
double	_yn (int, double);
int	_matherr (struct _exception *);

/* These are also declared in Mingw float.h; needed here as well to work 
   around GCC build issues.  */
/* BEGIN FLOAT.H COPY */
/*
 * IEEE recommended functions
 */

double	_chgsign	(double);
double	_copysign	(double, double);
double	_logb		(double);
double	_nextafter	(double, double);
double	_scalb		(double, long);

int	_finite		(double);
int	_fpclass	(double);
int	_isnan		(double);

/* END FLOAT.H COPY */

#if !defined (_NO_OLDNAMES)  \
   || (defined (__STDC_VERSION__) && __STDC_VERSION__ >= 199901L )

/*
 * Non-underscored versions of non-ANSI functions. These reside in
 * liboldnames.a. They are now also ISO C99 standand names.
 * Provided for extra portability.
 */

double cabs (struct _complex);
double hypot (double, double);
double j0 (double);
double j1 (double);
double jn (int, double);
double y0 (double);
double y1 (double);
double yn (int, double);

#endif	/* Not _NO_OLDNAMES */

#endif	/* Not __STRICT_ANSI__ */

#ifdef __cplusplus
}
#endif
#endif	/* Not RC_INVOKED */


#ifndef __NO_ISOCEXT

#define INFINITY HUGE_VAL
#define NAN (0.0F/0.0F)

/*
   Return values for fpclassify.
   These are based on Intel x87 fpu condition codes
   in the high byte of status word and differ from
   the return values for MS IEEE 754 extension _fpclass()
*/
#define FP_NAN		0x0100
#define FP_NORMAL	0x0400
#define FP_INFINITE	(FP_NAN | FP_NORMAL)
#define FP_ZERO		0x4000
#define FP_SUBNORMAL	(FP_NORMAL | FP_ZERO)
/* 0x0200 is signbit mask */

#ifndef RC_INVOKED
#ifdef __cplusplus
extern "C" {
#endif

double nan(const char *tagp);
float nanf(const char *tagp);

#ifndef __STRICT_ANSI__
#define nan() nan("")
#define nanf() nanf("")
#endif


/*
  We can't inline float, because we want to ensure truncation
  to semantic type before classification.  If we extend to long
  double, we will also need to make double extern only.
  (A normal long double value might become subnormal when 
  converted to double, and zero when converted to float.)
*/
extern __inline__ int __fpclassify (double x){
  unsigned short sw;
  __asm__ ("fxam; fstsw %%ax;" : "=a" (sw): "t" (x));
  return sw & (FP_NAN | FP_NORMAL | FP_ZERO );
}

extern int __fpclassifyf (float);

#define fpclassify(x) ((sizeof(x) == sizeof(float)) ? __fpclassifyf(x) \
		       :  __fpclassify(x))

/* We don't need to worry about trucation here:
   A NaN stays a NaN. */

extern __inline__ int __isnan (double _x)
{
  unsigned short sw;
  __asm__ ("fxam;"
	   "fstsw %%ax": "=a" (sw) : "t" (_x));
  return (sw & (FP_NAN | FP_NORMAL | FP_INFINITE | FP_ZERO | FP_SUBNORMAL))
    == FP_NAN;
}

extern __inline__ int __isnanf (float _x)
{
  unsigned short sw;
  __asm__ ("fxam;"
	    "fstsw %%ax": "=a" (sw) : "t" (_x));
  return (sw & (FP_NAN | FP_NORMAL | FP_INFINITE | FP_ZERO | FP_SUBNORMAL))
    == FP_NAN;
}

#define isnan(x) ((sizeof(x) == sizeof(float)) ? __isnanf(x) \
		       :  __isnan(x))


#define isfinite(x) ((fpclassify(x) & FP_NAN) == 0)
#define isinf(x) (fpclassify(x) == FP_INFINITE)
#define isnormal(x) (fpclassify(x) == FP_NORMAL)


extern __inline__ int __signbit (double x) {
  unsigned short stw;
  __asm__ ( "fxam; fstsw %%ax;": "=a" (stw) : "t" (x));
  return stw & 0x0200;
}

extern  __inline__ int __signbitf (float x) {
  unsigned short stw;
  __asm__ ("fxam; fstsw %%ax;": "=a" (stw) : "t" (x));
  return stw & 0x0200;
}

#define signbit(x) ((sizeof(x) == sizeof(float)) ? __signbitf(x) \
		    : __signbit(x))
/* 
 *  With these functions, comparisons involving quiet NaNs set the FP
 *  condition code to "unordered".  The IEEE floating-point spec
 *  dictates that the result of floating-point comparisons should be
 *  false whenever a NaN is involved, with the exception of the !=, 
 *  which always returns true.
 */

#if __GNUC__ >= 3

#define isgreater(x, y) __builtin_isgreater(x, y)
#define isgreaterequal(x, y) __builtin_isgreaterequal(x, y)
#define isless(x, y) __builtin_isless(x, y)
#define islessequal(x, y) __builtin_islessequal(x, y)
#define islessgreater(x, y) __builtin_islessgreater(x, y)
#define isunordered(x, y) __builtin_isunordered(x, y)

#else
/*  helper  */
extern  __inline__ int __fp_unordered_compare (double x,  double y){
  unsigned short retval;
  __asm__ ("fucom %%st(1);"
	   "fnstsw;": "=a" (retval) : "t" (x), "u" (y));
  return retval;
}

#define isgreater(x, y) ((__fp_unordered_compare(x, y) \
			   & 0x4500) == 0)
#define isless(x, y) ((__fp_unordered_compare (y, x) \
                       & 0x4500) == 0)
#define isgreaterequal(x, y) ((__fp_unordered_compare (x, y) \
                               & FP_INFINITE) == 0)
#define islessequal(x, y) ((__fp_unordered_compare(y, x) \
			    & FP_INFINITE) == 0)
#define islessgreater(x, y) ((__fp_unordered_compare(x, y) \
			      & FP_SUBNORMAL) == 0)
#define isunordered(x, y) ((__fp_unordered_compare(x, y) \
			    & 0x4500) == 0x4500)

#endif

/* round, using fpu control word settings */
extern  __inline__ double rint (double x)
{
  double retval;
  __asm__ ("frndint;": "=t" (retval) : "0" (x));
  return retval;
}

extern  __inline__ float rintf (float x)
{
  float retval;
  __asm__ ("frndint;" : "=t" (retval) : "0" (x) );
  return retval;
}

/* round away from zero, regardless of fpu control word settings */
extern double round (double);
extern float roundf (float);

/* round towards zero, regardless of fpu control word settings */
extern double trunc (double);
extern float truncf (float);


/* fmax and fmin.
   NaN arguments are treated as missing data: if one argument is a NaN and the other numeric, then the
   these functions choose the numeric value.
*/

extern double fmax  (double, double);
extern double fmin (double, double);
extern float fmaxf (float, float);
float fminf (float, float);

/* return x * y + z as a ternary op */ 
extern double fma (double, double, double);
extern float fmaf (float, float, float);

/* one lonely transcendental */
extern double log2 (double _x);
extern float log2f (float _x);

/* The underscored versions are in MSVCRT.dll.
   The stubs for these are in libmingwex.a */

double copysign (double, double);
float copysignf (float, float);
double logb (double);
float logbf (float);
double nextafter (double, double);
float nextafterf (float, float);
double scalb (double, long);
float scalbf (float, long);

#if !defined (__STRICT_ANSI__)  /* inline using non-ANSI functions */
extern  __inline__ double copysign (double x, double y)
	{ return _copysign(x, y); }
extern  __inline__ float copysignf (float x, float y)
	{ return  _copysign(x, y); } 
extern  __inline__ double logb (double x)
	{ return _logb(x); }
extern  __inline__ float logbf (float x)
	{ return  _logb(x); }
extern  __inline__ double nextafter(double x, double y)
	{ return _nextafter(x, y); }
extern  __inline__ float nextafterf(float x, float y)
	{ return _nextafter(x, y); }
extern  __inline__ double scalb (double x, long i)
	{ return _scalb (x, i); }
extern  __inline__ float scalbf (float x, long i)
	{ return _scalb(x, i); }
#endif /* (__STRICT_ANSI__)  */

#ifdef __cplusplus
}
#endif
#endif	/* Not RC_INVOKED */

#endif /* __NO_ISOCEXT */

#endif	/* Not _MATH_H_ */

