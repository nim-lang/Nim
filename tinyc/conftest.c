#include <stdio.h>

/* Define architecture */
#if defined(__i386__) || defined _M_IX86
# define TRIPLET_ARCH "i386"
#elif defined(__x86_64__) || defined _M_AMD64
# define TRIPLET_ARCH "x86_64"
#elif defined(__arm__)
# define TRIPLET_ARCH "arm"
#elif defined(__aarch64__)
# define TRIPLET_ARCH "aarch64"
#else
# define TRIPLET_ARCH "unknown"
#endif

/* Define OS */
#if defined (__linux__)
# define TRIPLET_OS "linux"
#elif defined (__FreeBSD__) || defined (__FreeBSD_kernel__)
# define TRIPLET_OS "kfreebsd"
#elif defined _WIN32
# define TRIPLET_OS "win32"
#elif !defined (__GNU__)
# define TRIPLET_OS "unknown"
#endif

/* Define calling convention and ABI */
#if defined (__ARM_EABI__)
# if defined (__ARM_PCS_VFP)
#  define TRIPLET_ABI "gnueabihf"
# else
#  define TRIPLET_ABI "gnueabi"
# endif
#else
# define TRIPLET_ABI "gnu"
#endif

#if defined _WIN32
# define TRIPLET TRIPLET_ARCH "-" TRIPLET_OS
#elif defined __GNU__
# define TRIPLET TRIPLET_ARCH "-" TRIPLET_ABI
#else
# define TRIPLET TRIPLET_ARCH "-" TRIPLET_OS "-" TRIPLET_ABI
#endif

#if defined(_WIN32)
int _CRT_glob = 0;
#endif

int main(int argc, char *argv[])
{
    switch(argc == 2 ? argv[1][0] : 0) {
        case 'b':
        {
            volatile unsigned foo = 0x01234567;
            puts(*(unsigned char*)&foo == 0x67 ? "no" : "yes");
            break;
        }
#ifdef __GNUC__
        case 'm':
            printf("%d\n", __GNUC_MINOR__);
            break;
        case 'v':
            printf("%d\n", __GNUC__);
            break;
#elif defined __TINYC__
        case 'v':
            puts("0");
            break;
        case 'm':
            printf("%d\n", __TINYC__);
            break;
#else
        case 'm':
        case 'v':
            puts("0");
            break;
#endif
        case 't':
            puts(TRIPLET);
            break;

        default:
            break;
    }
    return 0;
}
