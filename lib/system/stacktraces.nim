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
      nimcall, gcsafe, raises: [], tags: [], noinline.}
    StackTraceOverrideGetProgramCountersProc* = proc (maxLength: cint): seq[cuintptr_t] {.
      nimcall, gcsafe, raises: [], tags: [], noinline.}
    StackTraceOverrideGetDebuggingInfoProc* =
      proc (programCounters: seq[cuintptr_t], maxLength: cint): seq[StackTraceEntry] {.
        nimcall, gcsafe, raises: [], tags: [], noinline.}



  # Default procedures (not normally used, because people opting in on this
  # override are supposed to register their own versions).
  var
    stackTraceOverrideGetTraceback: StackTraceOverrideGetTracebackProc =
      proc (): string {.nimcall, gcsafe, raises: [], tags: [], noinline.} =
        discard
        #result = "Stack trace override procedure not registered.\n"
    stackTraceOverrideGetProgramCounters: StackTraceOverrideGetProgramCountersProc =
      proc (maxLength: cint): seq[cuintptr_t] {.nimcall, gcsafe, raises: [], tags: [], noinline.} =
        discard
    stackTraceOverrideGetDebuggingInfo: StackTraceOverrideGetDebuggingInfoProc =
      proc (programCounters: seq[cuintptr_t], maxLength: cint): seq[StackTraceEntry] {.
        nimcall, gcsafe, raises: [], tags: [], noinline.} =
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
    for i in 0..<programCounters.len:
      s.add(StackTraceEntry(programCounter: cast[uint](programCounters[i])))

  proc patchStackTraceEntry(x: var StackTraceEntry) =
    x.procname = x.procnameStr.cstring
    x.filename = x.filenameStr.cstring

  proc addStackTraceEntrySeq(result: var seq[StackTraceEntry]; s: seq[StackTraceEntry]) =
    for i in 0..<s.len:
      result.add(s[i])
      patchStackTraceEntry(result[result.high])

  # We may have more stack trace lines in the output, due to inlined procedures.
  proc addDebuggingInfo*(s: seq[StackTraceEntry]): seq[StackTraceEntry] =
    var programCounters: seq[cuintptr_t]
    # We process program counters in groups from complete stack traces, because
    # we have logic that keeps track of certain functions being inlined or not.
    for i in 0..<s.len:
      let entry = addr s[i]
      if entry.procname.isNil and entry.programCounter != 0:
        programCounters.add(cast[cuintptr_t](entry.programCounter))
      elif entry.procname.isNil and (entry.line == reraisedFromBegin or entry.line == reraisedFromEnd):
        result.addStackTraceEntrySeq(stackTraceOverrideGetDebuggingInfo(programCounters, maxStackTraceLines))
        programCounters = @[]
        result.add(entry[])
        patchStackTraceEntry(result[result.high])
      else:
        result.add(entry[])
        patchStackTraceEntry(result[result.high])
    if programCounters.len > 0:
      result.addStackTraceEntrySeq(stackTraceOverrideGetDebuggingInfo(programCounters, maxStackTraceLines))
