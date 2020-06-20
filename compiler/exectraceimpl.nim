import sem, semdata, ast, options

import std/exectraces

{.emit: "NIM_EXTERNC".}
proc nimExecTraceControl(c: PContext, n: PNode): PNode {.exportc.} =
  let mode = c.semConstExpr(c, n[1])
  let mode2 = TraceAction(mode.intVal)
  case mode2
  of kstart:
    c.config.options.incl(optExecTrace)
  of kstop:
    c.config.options.excl(optExecTrace)
  result = newNodeI(nkEmpty, n.info)
