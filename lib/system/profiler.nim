#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the Nim profiler. The profiler needs support by the
# code generator. The idea is to inject the instruction stream
# with 'nimProfile()' calls. These calls are injected at every loop end
# (except perhaps loops that have no side-effects). At every Nth call a
# stack trace is taken. A stack tace is a list of cstrings.

when defined(profiler) and defined(memProfiler):
  {.error: "profiler and memProfiler cannot be defined at the same time (See Embedded Stack Trace Profiler (ESTP) User Guide) for more details".}

{.push profiler: off.}

const
  MaxTraceLen = 20 # tracking the last 20 calls is enough

type
  StackTrace* = object
    lines*: array[0..MaxTraceLen-1, cstring]
    files*: array[0..MaxTraceLen-1, cstring]
  ProfilerHook* = proc (st: StackTrace) {.nimcall.}

proc `[]`*(st: StackTrace, i: int): cstring = st.lines[i]

proc captureStackTrace(f: FrameIndex, st: var StackTrace) =
  const
    firstCalls = 5
  var
    it = f
    i = 0
    total = 0
  while it != 0 and i <= high(st.lines)-(firstCalls-1):
    let fr = it.getCurrentFrameInternal
    # the (-1) is for the "..." entry
    st.lines[i] = fr.procname
    st.files[i] = fr.filename
    inc(i)
    inc(total)
    it.dec
  var b = it
  while it != 0:
    inc(total)
    it.dec
  for j in 1..total-i-(firstCalls-1):
    if b != 0: b.dec
  if total != i:
    st.lines[i] = "..."
    st.files[i] = "..."
    inc(i)
  while b != 0 and i <= high(st.lines):
    let fr = b.getCurrentFrameInternal
    st.lines[i] = fr.procname
    st.files[i] = fr.filename
    inc(i)
    b.dec

var
  profilingRequestedHook*: proc (): bool {.nimcall, locks: 0, gcsafe.}
    ## set this variable to provide a procedure that implements a profiler in
    ## user space. See the `nimprof` module for a reference implementation.

when defined(memProfiler):
  type
    MemProfilerHook* = proc (st: StackTrace, requestedSize: int) {.nimcall, locks: 0, gcsafe.}

  var
    profilerHook*: MemProfilerHook
      ## set this variable to provide a procedure that implements a profiler in
      ## user space. See the `nimprof` module for a reference implementation.

  proc callProfilerHook(hook: MemProfilerHook, requestedSize: int) =
    var st: StackTrace
    captureStackTrace(frameData.frameIndex, st)
    hook(st, requestedSize)

  proc nimProfile(requestedSize: int) =
    if not isNil(profilingRequestedHook) and profilingRequestedHook():
      callProfilerHook(profilerHook, requestedSize)
else:
  var
    profilerHook*: ProfilerHook
      ## set this variable to provide a procedure that implements a profiler in
      ## user space. See the `nimprof` module for a reference implementation.

  proc callProfilerHook(hook: ProfilerHook) {.noinline.} =
    # 'noinline' so that 'nimProfile' does not perform the stack allocation
    # in the common case.
    when not defined(nimdoc):
      var st: StackTrace
      captureStackTrace(frameData.frameIndex, st)
      hook(st)

  proc nimProfile() =
    ## This is invoked by the compiler in every loop and on every proc entry!
    if not isNil(profilingRequestedHook) and profilingRequestedHook():
      callProfilerHook(profilerHook)

{.pop.}
