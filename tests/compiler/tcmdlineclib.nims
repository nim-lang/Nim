import os

selfExec "c --app:lib " & (projectDir() / "samplelib.nim")
switch("clibdir", projectDir())
--clib:samplelib

# Make test executable can load sample shared library.
switch("passL", "-Wl,-rpath," & projectDir())
