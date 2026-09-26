discard """
  cmd: "nim $target --app:lib --nimcache:$filedir/nimcache_sampleclib $filedir/sampleclib.nim && $nim $target --clibdir:$filedir --passL:-Wl,-rpath,$filedir $options $file"
"""

# `{.clib.}` alone: the library is linked directly with `-l<lib>` (no dlopen).
# The ``cmd:`` above builds ``sampleclib.nim`` into a shared library, then links
# this program against it with ``-lsampleclib`` (via the ``{.clib.}`` pragma)
# and sets an rpath so the executable finds it at run time.
proc sampleclibAdd(a, b: int): int {.clib: "sampleclib", importc: "sampleclib_add", cdecl.}

doAssert sampleclibAdd(1, 2) == 3
doAssert sampleclibAdd(10, 20) == 30
