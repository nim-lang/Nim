{.used.}

include system/inclrtl

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

type TraceData = object
  depth: int
  numEnter: int

var traceData {.threadvar.}: TraceData

# {.pragma: prag, exportc, compilerRtl, inl, raises: [].}
{.push exectrace:off, stacktrace:off.}
# {.pragma: prag, exportc, exectrace:off.}
{.pragma: prag, exportc.}

proc nimExecTraceEnter(s: PFrame) {.prag.} =
  #[
  TODO: allow for NimStackTraceMsgs
  ]#
  traceData.depth.inc
  traceData.numEnter.inc
  let depth2 = cast[cint](traceData.depth)
  c_printf "[%2d]%*s > %s %d %s:%d\n", depth2, depth2*2, " ", s.procname, traceData.numEnter.cint, s.filename, s.line.cint
  # if framePtr == nil:
  #   s.calldepth = 0
  #   when NimStackTraceMsgs: s.frameMsgLen = 0
  # else:
  #   s.calldepth = framePtr.calldepth+1
  #   when NimStackTraceMsgs: s.frameMsgLen = framePtr.frameMsgLen
  # s.prev = framePtr
  # framePtr = s
  # if s.calldepth == nimCallDepthLimit: callDepthLimitReached()

proc nimExecTraceLine(s: PFrame, line: int16) {.prag.} =
  # if s == nil:
  #   # TODO; maybe the init procs? or the very first frame? handle it
  #   return
  # if traceData.numEnter < 346: return
  # let line = s.line.cint
  let line = line.cint
  let depth2 = cast[cint](traceData.depth)
  # c_printf "[%2d]%*s | %s %d %s:%d\n", depth2, depth2*2, " ", s.procname, traceData.numEnter.cint, s.filename, s.line.cint
  # c_printf "| %d\n", s.line.cint
  # c_printf "| %d ok:%d\n", depth2, cint(ok)
  # c_printf "| %d \n", depth2
  c_printf "| %d\n", line.cint

proc nimExecTraceExit {.prag.} =
  if false:
    let depth2 = cast[cint](traceData.depth)
    c_printf "[%2d]%*s <\n", depth2, depth2*2, " "
  traceData.depth.dec
  # framePtr = framePtr.prev
  # proc nimExecTraceExit(s: PFrame) {.compilerRtl, inl, raises: [].} =
  # nimGetFramePtrInternal = nimGetFramePtrInternal.prev
{.pop.}
