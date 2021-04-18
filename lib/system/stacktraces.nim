#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Additional code for customizable stack traces. Unstable API, for internal
# usage only.

const
  reraisedFromBegin* = -10
  reraisedFromEnd* = -100
  maxStackTraceLines* = 128

when defined(nimStackTraceOverride):
  ## Procedure types for overriding the default stack trace.
  type
    cuintptr_t* {.importc: "uintptr_t", nodecl.} = uint
      ## This is the same as the type `uintptr_t` in C.

    StackTraceOverrideGetTracebackProc* = proc (): string {.
      nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.}
    StackTraceOverrideGetProgramCountersProc* = proc (maxLength: cint): seq[cuintptr_t] {.
      nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.}
    StackTraceOverrideGetDebuggingInfoProc* =
      proc (programCounters: seq[cuintptr_t], maxLength: cint): seq[StackTraceEntry] {.
        nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.}

  # Default procedures (not normally used, because people opting in on this
  # override are supposed to register their own versions).
  var
    stackTraceOverrideGetTraceback: StackTraceOverrideGetTracebackProc =
      proc (): string {.nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.} =
        discard
        #result = "Stack trace override procedure not registered.\n"
    stackTraceOverrideGetProgramCounters: StackTraceOverrideGetProgramCountersProc =
      proc (maxLength: cint): seq[cuintptr_t] {.nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.} =
        discard
    stackTraceOverrideGetDebuggingInfo: StackTraceOverrideGetDebuggingInfoProc =
      proc (programCounters: seq[cuintptr_t], maxLength: cint): seq[StackTraceEntry] {.
        nimcall, gcsafe, locks: 0, raises: [], tags: [], noinline.} =
          discard

  # Custom procedure registration.
  proc registerStackTraceOverride*(overrideProc: StackTraceOverrideGetTracebackProc) =
    ## Override the default stack trace inside rawWriteStackTrace() with your
    ## own procedure.
    stackTraceOverrideGetTraceback = overrideProc
  proc registerStackTraceOverrideGetProgramCounters*(overrideProc: StackTraceOverrideGetProgramCountersProc) =
    stackTraceOverrideGetProgramCounters = overrideProc
  proc registerStackTraceOverrideGetDebuggingInfo*(overrideProc: StackTraceOverrideGetDebuggingInfoProc) =
    stackTraceOverrideGetDebuggingInfo = overrideProc

  # Custom stack trace manipulation.
  proc auxWriteStackTraceWithOverride*(s: var string) =
    add(s, stackTraceOverrideGetTraceback())

  proc auxWriteStackTraceWithOverride*(s: var seq[StackTraceEntry]) =
    let programCounters = stackTraceOverrideGetProgramCounters(maxStackTraceLines)
    if s.len == 0:
      s = newSeqOfCap[StackTraceEntry](programCounters.len)
    for programCounter in programCounters:
      s.add(StackTraceEntry(programCounter: cast[uint](programCounter)))

  # We may have more stack trace lines in the output, due to inlined procedures.
  proc addDebuggingInfo*(s: seq[StackTraceEntry]): seq[StackTraceEntry] =
    var programCounters: seq[cuintptr_t]
    # We process program counters in groups from complete stack traces, because
    # we have logic that keeps track of certain functions being inlined or not.
    for entry in s:
      if entry.procname.isNil and entry.programCounter != 0:
        programCounters.add(cast[cuintptr_t](entry.programCounter))
      elif entry.procname.isNil and (entry.line == reraisedFromBegin or entry.line == reraisedFromEnd):
        result.add(stackTraceOverrideGetDebuggingInfo(programCounters, maxStackTraceLines))
        programCounters = @[]
        result.add(entry)
      else:
        result.add(entry)
    if programCounters.len > 0:
      result.add(stackTraceOverrideGetDebuggingInfo(programCounters, maxStackTraceLines))
