# Module-level emits used by bodies that IC may emit into an importer's TU.

# Preprocessor-only: replayed wherever this module's bodies are emitted.
{.emit: """
#define NIM_IC_FOREIGN_EMIT_VALUE 5
""".}

# Defines a C function: must stay in this module's TU, or the program has two
# definitions of it.
{.emit: """
int nimIcForeignEmitHelper(int a) { return a + 1; }
""".}

proc foreignEmitHelper(a: cint): cint {.importc: "nimIcForeignEmitHelper", nodecl.}

proc foreignEmitValue*(): int =
  # Not used in this module, so the importer's TU emits it.
  {.emit: "`result` = NIM_IC_FOREIGN_EMIT_VALUE;".}

proc foreignEmitGeneric*[T](x: T): T =
  var v: int
  {.emit: "`v` = NIM_IC_FOREIGN_EMIT_VALUE;".}
  x + T(v)

proc foreignEmitHelped*(a: int): int = int(foreignEmitHelper(cint a))
