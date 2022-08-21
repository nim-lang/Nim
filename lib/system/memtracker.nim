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

when declared(getThreadId):
  template myThreadId(): untyped = getThreadId()
else:
  template myThreadId(): untyped = 0

type
  LogEntry* = object
    op*: cstring
    address*: pointer
    size*: int
    file*: cstring
    line*: int
    thread*: int
  TrackLog* = object
    count*: int
    disabled: bool
    data*: array[400, LogEntry]
  TrackLogger* = proc (log: TrackLog) {.nimcall, tags: [], locks: 0, gcsafe.}

var
  gLog*: TrackLog
  gLogger*: TrackLogger = proc (log: TrackLog) = discard
  ilocs: array[4000, (int, int)]
  ilocn: int

proc trackLocation*(p: pointer; size: int) =
  let x = (cast[int](p), size)
  for i in 0..ilocn-1:
    # already known?
    if ilocs[i] == x: return
  ilocs[ilocn] = x
  inc ilocn

proc setTrackLogger*(logger: TrackLogger) =
  gLogger = logger

proc addEntry(entry: LogEntry) =
  if not gLog.disabled:
    var interesting = false
    for i in 0..ilocn-1:
      let p = ilocs[i]
      #  X..Y and C..D overlap iff (X <= D and C <= Y)
      let x = p[0]
      let y = p[0]+p[1]-1
      let c = cast[int](entry.address)
      let d = c + entry.size-1
      if x <= d and c <= y:
        interesting = myThreadId() != entry.thread # true
        break
    if interesting:
      gLog.disabled = true
      cprintf("interesting %s:%ld %s\n", entry.file, entry.line, entry.op)
      let x = cast[proc() {.nimcall, tags: [], gcsafe, locks: 0, raises: [].}](writeStackTrace)
      x()
      quit 1
      #if gLog.count > high(gLog.data):
      #  gLogger(gLog)
      #  gLog.count = 0
      #gLog.data[gLog.count] = entry
      #inc gLog.count
      #gLog.disabled = false

proc memTrackerWrite(address: pointer; size: int; file: cstring; line: int) {.compilerproc.} =
  addEntry LogEntry(op: "write", address: address,
      size: size, file: file, line: line, thread: myThreadId())

proc memTrackerOp*(op: cstring; address: pointer; size: int) {.tags: [],
         locks: 0, gcsafe.} =
  addEntry LogEntry(op: op, address: address, size: size,
      file: "", line: 0, thread: myThreadId())

proc memTrackerDisable*() =
  gLog.disabled = true

proc memTrackerEnable*() =
  gLog.disabled = false

proc logPendingOps() {.noconv.} =
  # forward declared and called from Nim's signal handler.
  gLogger(gLog)
  gLog.count = 0

import std/exitprocs
addExitProc logPendingOps

{.pop.}
