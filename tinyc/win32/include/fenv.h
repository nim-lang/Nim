#ifndef _FENV_H
#define _FENV_H

/*
  For now, support only for the basic abstraction of flags that are
  either set or clear. fexcept_t could be  structure that holds more info
  about the fp environment.
*/
typedef unsigned short fexcept_t;

/* This 28-byte struct represents the entire floating point
   environment as stored by fnstenv or fstenv */
typedef struct
{
  unsigned short __control_word;
  unsigned short __unused0;
  unsigned short __status_word;
  unsigned short __unused1;
  unsigned short __tag_word;
  unsigned short __unused2;  
  unsigned int	 __ip_offset;    /* instruction pointer offset */
  unsigned short __ip_selector;  
  unsigned short __opcode;
  unsigned int	 __data_offset;
  unsigned short __data_selector;  
  unsigned short __unused3;
} fenv_t;


/* FPU status word exception flags */
#define FE_INVALID	0x01
#define FE_DENORMAL	0x02
#define FE_DIVBYZERO	0x04
#define FE_OVERFLOW	0x08
#define FE_UNDERFLOW	0x10
#define FE_INEXACT	0x20
#define FE_ALL_EXCEPT (FE_INVALID | FE_DENORMAL | FE_DIVBYZERO \
		       | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)

/* FPU control word rounding flags */
#define FE_TONEAREST	0x0000
#define FE_DOWNWARD	0x0400
#define FE_UPWARD	0x0800
#define FE_TOWARDZERO	0x0c00


/* The default floating point environment */
#define FE_DFL_ENV ((const fenv_t *)-1)


#ifndef RC_INVOKED
#ifdef __cplusplus
extern "C" {
#endif


/*TODO: Some of these could be inlined */
/* 7.6.2 Exception */

extern int feclearexcept (int);
extern int fegetexceptflag (fexcept_t * flagp, int excepts);
extern int feraiseexcept (int excepts );
extern int fesetexceptflag (const fexcept_t *, int);
extern int fetestexcept (int excepts);


/* 7.6.3 Rounding */

extern int fegetround (void);
extern int fesetround (int mode);


/* 7.6.4 Environment */

extern int fegetenv (fenv_t * envp);
extern int fesetenv (const fenv_t * );
extern int feupdateenv (const fenv_t *);
extern int feholdexcept (fenv_t *);

#ifdef __cplusplus
}
#endif
#endif	/* Not RC_INVOKED */

#endif /* ndef _FENV_H */
