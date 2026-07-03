# Helper for temit.nim: a NON-main module with a module-scope `{.emit.}` that
# introduces a C macro consumed by an `{.importc, nodecl.}` const. The IC backend
# reload used to drop top-level emit pragmas — writeToplevelNode wrote them to the
# by-symbol-index implementation section, where a symbol-less pragma is never
# reloaded — so the generated C lost the `#define` and failed to compile with
# "use of undeclared identifier". Mirrors lib/pure/concurrency/cpuinfo.nim's
# `#include <sys/sysctl.h>` + `CTL_HW`/`HW_NCPU` importc pattern.
{.emit: """/*TYPESECTION*/
#define NIM_IC_EMIT_ANSWER 42
""".}

let icEmitAnswer {.importc: "NIM_IC_EMIT_ANSWER", nodecl.}: cint

proc emitAnswer*(): int = int(icEmitAnswer)
