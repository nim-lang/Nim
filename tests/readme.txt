This directory contains the test cases.
Each test must have a filename of the form: ``t*.nim``

Each test can contain a spec in a ``discard """"""`` block.

The folder ``rodfiles`` contains special tests that test incremental
compilation via symbol files.

The folder ``dll`` contains simple DLL tests.

The folder ``realtimeGC`` contains a test for validating that the realtime GC
can run properly without linking against the nimrtl.dll/so. It includes a C
client and platform specific build files for manual compilation.
