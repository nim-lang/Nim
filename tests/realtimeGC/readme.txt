Test the realtime GC without linking nimrtl.dll/so.

Note, this is a long running test, default is 35 minutes. To change the
the run time see RUNTIME in nmain.nim and cmain.c.

You can build shared.nim, nmain.nim, and cmain.c by running make (nix systems)
or make.bat (Windows systems). They both assume GCC and that it's in your
path. Output: shared.(dll/so), cmain(.exe), nmain(.exe).

To run the test: execute either nmain or cmain in a shell window.

To build by hand:

  - build the shared object (shared.nim):

    $ nim c tests/realtimeGC/shared.nim

  - build the client executables:

    $ nim c --threads:on tests/realtimeGC/nmain.nim
    $ gcc -o tests/realtimeGC/cmain tests/realtimeGC/cmain.c -ldl
