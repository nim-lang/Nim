#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Memory tracking support for Nim.

when not defined(memTracker):
  {.error: "Memory tracking support is turned off! Enable memory tracking by passing `--memtracker:on` to the compiler (see the Nim Compiler User Guide for more options).".}

when defined(noSignalHandler):
  {.error: "Memory tracking works better with the default signal handler.".}

# We don't want to memtrack the tracking code ...
{.push memtracker: off.}

type
  LogEntry* = object
    op*: cstring
    address*: pointer
    size*: int
    file*: cstring
    line*: int
  TrackLog* = object
    count*: int
    disabled: bool
    data*: array[4000, LogEntry]
  TrackLogger* = proc (log: TrackLog) {.nimcall, tags: [], locks: 0.}

var
  gLog*: TrackLog
  gLogger*: TrackLogger = proc (log: TrackLog) = discard

proc setTrackLogger*(logger: TrackLogger) =
  gLogger = logger

proc addEntry(entry: LogEntry) =
  if not gLog.disabled:
    if gLog.count > high(gLog.data):
      gLogger(gLog)
      gLog.count = 0
    gLog.data[gLog.count] = entry
    inc gLog.count

proc memTrackerWrite(address: pointer; size: int; file: cstring; line: int) {.compilerProc.} =
  addEntry LogEntry(op: "write", address: address,
      size: size, file: file, line: line)

proc memTrackerOp*(op: cstring; address: pointer; size: int) =
  addEntry LogEntry(op: op, address: address, size: size,
      file: "", line: 0)

proc memTrackerDisable*() =
  gLog.disabled = true

proc memTrackerEnable*() =
  gLog.disabled = false

proc logPendingOps() {.noconv.} =
  # forward declared and called from Nim's signal handler.
  gLogger(gLog)
  gLog.count = 0

addQuitProc logPendingOps

{.pop.}
