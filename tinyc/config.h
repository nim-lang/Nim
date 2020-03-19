/* Modified to not rely on a configure script: */
#define CONFIG_SYSROOT ""
#define TCC_VERSION "0.9.27"

#if defined(WIN32) || defined(_WIN32)
#  define TCC_TARGET_PE   1
#  define TCC_TARGET_I386
#  define CONFIG_TCCDIR "."
#elif defined(__i386__)
#  define CONFIG_USE_LIBGCC
#  define TCC_TARGET_I386
#  define CONFIG_TCCDIR "/usr/local/lib/tcc"
#  define GCC_MAJOR 4
#  define HOST_I386 1
#else
#  define CONFIG_USE_LIBGCC
#  define TCC_TARGET_X86_64
#  define CONFIG_TCCDIR "/usr/local/lib/tcc"
#  define GCC_MAJOR 4
#  define HOST_X86_64 1
#endif

