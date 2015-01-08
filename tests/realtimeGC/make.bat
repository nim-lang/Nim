
set CXX=gcc
set LIBS=-ldl
set LNFLAGS=
set CFLAGS=-DWIN
set INC=

nim c shared.nim
nim c -o:nmain main.nim
%CXX% %INC% %DEFS% %CFLAGS% -o cmain main.c %LNFLAGS% %LIBS%
