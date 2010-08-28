//+---------------------------------------------------------------------------

#include <windows.h>

#define __UNKNOWN_APP    0
#define __CONSOLE_APP    1
#define __GUI_APP        2
void __set_app_type(int);
void _controlfp(unsigned a, unsigned b);

int _winstart(void)
{
	char *szCmd; STARTUPINFO startinfo;

	__set_app_type(__GUI_APP);
	_controlfp(0x10000, 0x30000);

	szCmd = GetCommandLine();
	if (szCmd)
	{
		while (' ' == *szCmd) szCmd++;
		if ('\"' == *szCmd)
		{
			while (*++szCmd)
				if ('\"' == *szCmd) { szCmd++; break; }
		}
		else
		{
			while (*szCmd && ' ' != *szCmd) szCmd++;
		}
		while (' ' == *szCmd) szCmd++;
	}

	GetStartupInfo(&startinfo);
	exit(WinMain(GetModuleHandle(NULL), NULL, szCmd,
		(startinfo.dwFlags & STARTF_USESHOWWINDOW) ?
			startinfo.wShowWindow : SW_SHOWDEFAULT));
}

int _runwinmain(int argc, char **argv)
{
	char *szCmd = NULL;
	char *p = GetCommandLine();
	if (argc > 1) szCmd = strstr(p, argv[1]);
	if (NULL == szCmd) szCmd = "";
	else if (szCmd > p && szCmd[-1] == '\"') --szCmd;
	return WinMain(GetModuleHandle(NULL), NULL, szCmd, SW_SHOWDEFAULT);
}

