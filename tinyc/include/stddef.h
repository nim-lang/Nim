#ifndef _STDDEF_H
#define _STDDEF_H

#define NULL ((void *)0)
typedef __SIZE_TYPE__ size_t;
typedef __WCHAR_TYPE__ wchar_t;
typedef __PTRDIFF_TYPE__ ptrdiff_t;
#define offsetof(type, field) ((size_t) &((type *)0)->field)

#ifndef __int8_t_defined
#define __int8_t_defined
typedef char int8_t;
typedef short int int16_t;
typedef int int32_t;
typedef long long int int64_t;
#endif

void *alloca(size_t size);

#endif
