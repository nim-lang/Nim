{.used.}

include system/inclrtl

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

type TraceData = object
  depth: int
  numEnter: int
  disabled: bool

var traceData {.threadvar.}: TraceData

{.push exectrace:off, stacktrace:off.}
{.pragma: prag, exportc.}
  # maybe these too: {.compilerRtl, inl, raises: [].}

proc enableRuntimeTracing*(ok: bool) =
  traceData.disabled = not ok

proc nimExecTraceEnter(s: PFrame) {.prag.} =
  #[
  TODO: allow for NimStackTraceMsgs
  ]#
  if not traceData.disabled:
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
  when true:
    if not traceData.disabled:
      let depth2 = cast[cint](traceData.depth)
      c_printf "[%2d]%*s | %s %d %s:%d\n", depth2, depth2*2, " ", s.procname, traceData.numEnter.cint, s.filename, s.line.cint

proc nimExecTraceExit {.prag.} =
  if not traceData.disabled:
    if false:
      let depth2 = cast[cint](traceData.depth)
      c_printf "[%2d]%*s <\n", depth2, depth2*2, " "
    traceData.depth.dec
    # framePtr = framePtr.prev
    # proc nimExecTraceExit(s: PFrame) {.compilerRtl, inl, raises: [].} =
    # nimGetFramePtrInternal = nimGetFramePtrInternal.prev
{.pop.}
