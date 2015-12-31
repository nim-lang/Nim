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
  StackTrace* = array [0..MaxTraceLen-1, cstring]
  ProfilerHook* = proc (st: StackTrace) {.nimcall.}
{.deprecated: [TStackTrace: StackTrace, TProfilerHook: ProfilerHook].}

proc captureStackTrace(f: PFrame, st: var StackTrace) =
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

var
  profilingRequestedHook*: proc (): bool {.nimcall, benign.}
    ## set this variable to provide a procedure that implements a profiler in
    ## user space. See the `nimprof` module for a reference implementation.

when defined(memProfiler):
  type
    MemProfilerHook* = proc (st: StackTrace, requestedSize: int) {.nimcall, benign.}

  var
    profilerHook*: MemProfilerHook
      ## set this variable to provide a procedure that implements a profiler in
      ## user space. See the `nimprof` module for a reference implementation.

  proc callProfilerHook(hook: MemProfilerHook, requestedSize: int) =
    var st: StackTrace
    captureStackTrace(framePtr, st)
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
    var st: StackTrace
    captureStackTrace(framePtr, st)
    hook(st)

  proc nimProfile() =
    ## This is invoked by the compiler in every loop and on every proc entry!
    if not isNil(profilingRequestedHook) and profilingRequestedHook():
      callProfilerHook(profilerHook)

{.pop.}
