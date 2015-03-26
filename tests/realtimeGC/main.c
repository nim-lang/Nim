
#ifdef WIN
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>

#define RUNTIME (35*60)


typedef void (*pFunc)(void);

int main(int argc, char* argv[])
{
    int i;
    void* hndl;
    pFunc status;
    pFunc count;
    pFunc occupiedMem;

#ifdef WIN
    hndl = (void*) LoadLibrary((char const*)"./shared.dll");
    status = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"status");
    count = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"count");
    occupiedMem = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"occupiedMem");
#else /* OSX || NIX */
    hndl = (void*) dlopen((char const*)"./libshared.so", RTLD_LAZY);
    status = (pFunc) dlsym(hndl, (char const*)"status");
    count = (pFunc) dlsym(hndl, (char const*)"count");
    occupiedMem = (pFunc) dlsym(hndl, (char const*)"occupiedMem");
#endif

    assert(hndl);
    assert(status);
    assert(count);
    assert(occupiedMem);

    time_t startTime = time((time_t*)0);
    time_t runTime = (time_t)(RUNTIME);
    time_t accumTime = 0;
    while (accumTime < runTime) {
        for (i = 0; i < 10; i++)
            count();
        printf("1. sleeping...\n");
        sleep(1);
        for (i = 0; i < 10; i++)
            status();
        printf("2. sleeping...\n");
        sleep(1);
        occupiedMem();
        accumTime = time((time_t*)0) - startTime;
        printf("--- Minutes left to run: %d\n", (int)(runTime-accumTime)/60);
    }
    printf("Cleaning up the shared object pointer...\n");
#ifdef WIN
    FreeLibrary((HMODULE)hndl);
#else /* OSX || NIX */
    dlclose(hndl);
#endif
    printf("Done\n");
    return 0;
}




