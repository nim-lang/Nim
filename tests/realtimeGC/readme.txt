Test the realtime GC without linking nimrtl.dll/so.

Note, this is a long running test, default is 35 minutes. To change the
the run time see RUNTIME in main.nim and main.c.

You can build shared.nim, main.nim, and main.c by running make (nix systems)
or maike.bat (Windows systems). They both assume GCC and that it's in your
path. Output: shared.(dll/so), camin(.exe), nmain(.exe).

To run the test: execute either nmain or cmain in a shell window.

To build buy hand:

  - build the shared object (shared.nim):

    $ nim c shared.nim

  - build the client executables:

    $ nim c -o:nmain main.nim
    $ gcc -o cmain main.c -ldl
