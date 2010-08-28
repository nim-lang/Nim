@rem ----------------------------------------------------
@rem batch file to build tcc using gcc and ar from mingw
@rem ----------------------------------------------------
:
@echo>..\config.h #define TCC_VERSION "0.9.25"
@echo>>..\config.h #define TCC_TARGET_PE 1
@echo>>..\config.h #define CONFIG_TCCDIR "."
@echo>>..\config.h #define CONFIG_SYSROOT ""
:
gcc -Os -fno-strict-aliasing ../tcc.c -o tcc.exe -s
gcc -Os -fno-strict-aliasing ../libtcc.c -c -o libtcc.o
gcc -Os tools/tiny_impdef.c -o tiny_impdef.exe -s
gcc -Os tools/tiny_libmaker.c -o tiny_libmaker.exe -s
mkdir libtcc
ar rcs libtcc/libtcc.a libtcc.o
del libtcc.o
copy ..\libtcc.h libtcc
:
.\tcc -c lib/crt1.c
.\tcc -c lib/wincrt1.c
.\tcc -c lib/dllcrt1.c
.\tcc -c lib/dllmain.c
.\tcc -c lib/chkstk.S
.\tcc -c ../lib/libtcc1.c
.\tcc -c ../lib/alloca86.S
.\tcc -c ../lib/alloca86-bt.S
ar rcs lib/libtcc1.a crt1.o wincrt1.o dllcrt1.o dllmain.o chkstk.o libtcc1.o alloca86.o alloca86-bt.o
rem del *.o
