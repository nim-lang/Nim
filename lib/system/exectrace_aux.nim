include system/inclrtl

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

type TraceData = object
  depth: int

var traceData {.threadvar.}: TraceData

# {.pragma: prag, exportc, compilerRtl, inl, raises: [].}
{.push exectrace:off.}
# {.pragma: prag, exportc, exectrace:off.}
{.pragma: prag, exportc.}

proc nimExecTraceEnter(s: PFrame) {.prag.} =
  traceData.depth.inc
  let depth2 = cast[cint](traceData.depth)
  c_printf "[%2d]%*s > %s\n", depth2, depth2*2, " ", s.procname
  # if framePtr == nil:
  #   s.calldepth = 0
  #   when NimStackTraceMsgs: s.frameMsgLen = 0
  # else:
  #   s.calldepth = framePtr.calldepth+1
  #   when NimStackTraceMsgs: s.frameMsgLen = framePtr.frameMsgLen
  # s.prev = framePtr
  # framePtr = s
  # if s.calldepth == nimCallDepthLimit: callDepthLimitReached()

proc nimExecTraceExit {.prag.} =
  if false:
    let depth2 = cast[cint](traceData.depth)
    c_printf "[%2d]%*s <\n", depth2, depth2*2, " "
  traceData.depth.dec
  # framePtr = framePtr.prev
  # proc nimExecTraceExit(s: PFrame) {.compilerRtl, inl, raises: [].} =
  # nimGetFramePtrInternal = nimGetFramePtrInternal.prev
{.pop.}
