//+---------------------------------------------------------------------------

#include <windows.h>

BOOL WINAPI DllMain (HANDLE hDll, DWORD dwReason, LPVOID lpReserved);

BOOL WINAPI _dllstart(HANDLE hDll, DWORD dwReason, LPVOID lpReserved)
{
	BOOL bRet;
	bRet = DllMain (hDll, dwReason, lpReserved);
	return bRet;
}

