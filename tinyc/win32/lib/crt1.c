// =============================================
// crt1.c

#include <stdlib.h>

#define __UNKNOWN_APP    0
#define __CONSOLE_APP    1
#define __GUI_APP        2
void __set_app_type(int);
void _controlfp(unsigned a, unsigned b);

typedef struct
{
	int newmode;
} _startupinfo;

void __getmainargs(int *pargc, char ***pargv, char ***penv, int globb, _startupinfo*);

int main(int argc, char **argv, char **env);

int _start(void)
{
	int argc; char **argv; char **env; int ret;
	_startupinfo start_info = {0};

	_controlfp(0x10000, 0x30000);
	__set_app_type(__CONSOLE_APP);
	__getmainargs(&argc, &argv, &env, 0, &start_info);

	ret = main(argc, argv, env);
	exit(ret);
}

// =============================================

