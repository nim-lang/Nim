//+---------------------------------------------------------------------------
//
//  dll.c - Windows DLL example - dynamically linked part
//

#include <windows.h>

#define DLL_EXPORT __declspec(dllexport)


DLL_EXPORT void HelloWorld (void)
{
	MessageBox (0, "Hello World!", "From DLL", MB_ICONINFORMATION);
}

