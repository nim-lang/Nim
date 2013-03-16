#ifndef _EXCPT_H
#define _EXCPT_H
#if __GNUC__ >=3
#pragma GCC system_header
#endif

/* FIXME: This will make some code compile. The programs will most
   likely crash when an exception is raised, but at least they will
   compile. */
#ifdef __GNUC__
#define __try
#define __except(x) if (0) /* don't execute handler */
#define __finally

#define _try __try
#define _except __except
#define _finally __finally
#endif

#endif
