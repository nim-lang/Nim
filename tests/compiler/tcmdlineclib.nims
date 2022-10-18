import os

selfExec "c --app:lib " & (projectDir() / "samplelib.nim")
switch("clibdir", projectDir())
--clib:samplelib

# Make test executable can load sample shared library.
# `-rpath` option doesn't work and ignored on Windows.
# But the dll file in same directory as executable file is loaded.
switch("passL", "-Wl,-rpath," & projectDir())
