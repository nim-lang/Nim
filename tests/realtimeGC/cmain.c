#ifdef WIN
#include <windows.h>
#else
#include <dlfcn.h>
#include <unistd.h> /* for sleep(3) */
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>

#define RUNTIME (15*60)


typedef void (*pFunc)(void);

int main(int argc, char* argv[])
{
    int i;
    void* hndl;
    pFunc status;
    pFunc count;
    pFunc checkOccupiedMem;

#ifdef WIN
    hndl = (void*) LoadLibrary((char const*)"./tests/realtimeGC/shared.dll");
    status = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"status");
    count = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"count");
    checkOccupiedMem = (pFunc)GetProcAddress((HMODULE) hndl, (char const*)"checkOccupiedMem");
#else /* OSX || NIX */
    hndl = (void*) dlopen((char const*)"./tests/realtimeGC/libshared.so", RTLD_LAZY);
    status = (pFunc) dlsym(hndl, (char const*)"status");
    count = (pFunc) dlsym(hndl, (char const*)"count");
    checkOccupiedMem = (pFunc) dlsym(hndl, (char const*)"checkOccupiedMem");
#endif

    assert(hndl);
    assert(status);
    assert(count);
    assert(checkOccupiedMem);

    time_t startTime = time((time_t*)0);
    time_t runTime = (time_t)(RUNTIME);
    time_t accumTime = 0;
    while (accumTime < runTime) {
        for (i = 0; i < 10; i++)
            count();
        /* printf("1. sleeping...\n"); */
        sleep(1);
        for (i = 0; i < 10; i++)
            status();
        /* printf("2. sleeping...\n"); */
        sleep(1);
        checkOccupiedMem();
        accumTime = time((time_t*)0) - startTime;
        /* printf("--- Minutes left to run: %d\n", (int)(runTime-accumTime)/60); */
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
