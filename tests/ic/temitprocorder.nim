discard """
  output: "42 7"
"""

# Module-level emits and `{.exportc.}` routines keep their source order in C, as
# in a classic build.

# 1. A later emit calls an exported proc by its C name: the proc's prototype
#    must come first.
proc emitOrderAnswer(): cint {.cdecl, exportc: "nimIcEmitOrderAnswer".} = 42

{.emit: """
static int nimIcEmitOrderBridge(void) {
  return nimIcEmitOrderAnswer();
}
""".}

proc emitOrderBridge(): cint {.cdecl, importc: "nimIcEmitOrderBridge", nodecl.}

# 2. An earlier emit declares a C type used by a later exported proc's
#    signature: the emit must come first.
{.emit: """
typedef struct { int x; } NimIcEmitOrderPoint;
""".}

type EmitOrderPoint {.importc: "NimIcEmitOrderPoint", nodecl.} = object
  x: cint

proc pointX(p: EmitOrderPoint): cint {.exportc: "nimIcEmitOrderPointX".} = p.x

var p: EmitOrderPoint
p.x = 7
echo emitOrderBridge(), " ", pointX(p)
