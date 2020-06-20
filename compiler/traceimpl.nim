import sem, semdata, ast

import std/exectraces
# import timn/dbgs

NIM_EXPORTC
proc tranceControlImpl*(c: PContext, n: PNode): PNode {.exportc.} =
  # let n1 = n[1].
  # let mode = semConstExpr(c, n[1])
  let mode = c.semConstExpr(c, n[1])
  let mode2 = TraceAction(mode.intVal)
  dbg2 mode
  dbg mode2
  case mode2
  of kstart:
    c.config.options.incl(optExecTrace)
  of kstop:
    c.config.options.excl(optExecTrace)
  result = newNodeI(nkEmpty, n.info)
