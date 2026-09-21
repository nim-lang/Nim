# Shared library used by the ``{.clib.}`` test (``tclib.nim`` builds it via its
# ``cmd:`` spec). The ``dynlib`` pragma on the export makes the symbol actually
# exported from the ``.so`` (without it the symbol is ``N_LIB_PRIVATE`` and the
# linker DCEs it).
proc sampleclibAdd(a, b: int): int {.cdecl, exportc: "sampleclib_add", dynlib.} =
  a + b
