Test the realtime GC without linking nimrtl.dll/so.

To build by hand and run the test for 35 minutes:
    $ nim r --threads:on -d:runtimeSecs:2100 tests/realtimeGC/nmain.nim

```
xxx do we still need tests/realtimeGC/cmain.c?
if so, tests/realtimeGC/cmain.c needs to updated and factorized with nmain.nim to avoid duplication (even if it's a C file)
```
    $ gcc -o tests/realtimeGC/cmain tests/realtimeGC/cmain.c -ldl