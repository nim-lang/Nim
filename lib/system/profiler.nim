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

{.push profiler: off.}

const
  MaxTraceLen = 20 # tracking the last 20 calls is enough

type
  TStackTrace* = array [0..MaxTraceLen-1, cstring]
  TProfilerHook* = proc (st: TStackTrace) {.nimcall.}

proc captureStackTrace(f: PFrame, st: var TStackTrace) =
  const
    firstCalls = 5
  var
    it = f
    i = 0
    total = 0
  while it != nil and i <= high(st)-(firstCalls-1):
    # the (-1) is for the "..." entry
    st[i] = it.procname
    inc(i)
    inc(total)
    it = it.prev
  var b = it
  while it != nil:
    inc(total)
    it = it.prev
  for j in 1..total-i-(firstCalls-1): 
    if b != nil: b = b.prev
  if total != i:
    st[i] = "..."
    inc(i)
  while b != nil and i <= high(st):
    st[i] = b.procname
    inc(i)
    b = b.prev

when defined(memProfiler):
  type
    TMemProfilerHook* = proc (st: TStackTrace, requestedSize: int) {.nimcall.}
  var
    profilerHook*: TMemProfilerHook
      ## set this variable to provide a procedure that implements a profiler in
      ## user space. See the `nimprof` module for a reference implementation.

  proc callProfilerHook(hook: TMemProfilerHook, requestedSize: int) =
    var st: TStackTrace
    captureStackTrace(framePtr, st)
    hook(st, requestedSize)

  proc nimProfile(requestedSize: int) =
    if not isNil(profilerHook):
      callProfilerHook(profilerHook, requestedSize)
else:
  const
    SamplingInterval = 50_000
      # set this to change the default sampling interval
  var
    profilerHook*: TProfilerHook
      ## set this variable to provide a procedure that implements a profiler in
      ## user space. See the `nimprof` module for a reference implementation.
    gTicker {.threadvar.}: int

  proc callProfilerHook(hook: TProfilerHook) {.noinline.} =
    # 'noinline' so that 'nimProfile' does not perform the stack allocation
    # in the common case.
    var st: TStackTrace
    captureStackTrace(framePtr, st)
    hook(st)

  proc nimProfile() =
    ## This is invoked by the compiler in every loop and on every proc entry!
    if gTicker == 0:
      gTicker = -1
      if not isNil(profilerHook):
        # disable recursive calls: XXX should use try..finally,
        # but that's too expensive!
        let oldHook = profilerHook
        profilerHook = nil
        callProfilerHook(oldHook)
        profilerHook = oldHook
      gTicker = SamplingInterval
    dec gTicker

{.pop.}
