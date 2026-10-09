discard """
  output: "3"
  disabled: "windows" # N_LIB_IMPORT is __declspec(dllimport) there, which conflicts with the symbol defined locally in the C file
"""

# A bare ``{.dynlib.}`` (no library name) combined with ``importc`` declares
# the symbol ``N_LIB_IMPORT`` in the generated C (imported from a dynamic
# library). The symbol is provided by the compiled C file below.
{.compile: "tdynlibimport_impl.c".}
proc dynlibImportAdd(a, b: int): int {.importc: "dynlibimport_add", dynlib.}

echo dynlibImportAdd(1, 2)
