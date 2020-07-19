import ast, options
import semdata # PContext

# lifetime
# {.pragma: mylib, importc, dynlib: "/tmp/libz11.dylib".} # PRTEMP PATH
{.pragma: mylib, importc.} # PRTEMP PATH
proc nimCheckViewFromCompat*(c: PContext, n, le, ri: PNode) {.mylib.}
proc nimSimulateCall*(c: PContext, fun: PSym, nCall: PNode) {.mylib.}
proc nimToHumanViewConstraint*(a: seq[ViewConstraint]): string {.importc.}
