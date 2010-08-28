#ifndef _VARARGS_H
#define _VARARGS_H

#include <stdarg.h>

#define va_dcl
#define va_alist __va_alist
#undef va_start
#define va_start(ap) ap = __builtin_varargs_start

#endif
