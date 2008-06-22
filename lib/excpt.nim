#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Exception handling code. This is difficult because it has
# to work if there is no more memory. Thus we have to use
# a static string. Do not use ``sprintf``, etc. as they are
# unsafe!

when not defined(windows) or not defined(guiapp):
  proc writeToStdErr(msg: CString) = write(stdout, msg)

else:
  proc MessageBoxA(hWnd: cint, lpText, lpCaption: cstring, uType: int): int32 {.
    header: "<windows.h>", nodecl.}

  proc writeToStdErr(msg: CString) =
    discard MessageBoxA(0, msg, nil, 0)

proc raiseException(e: ref E_Base, ename: CString) {.compilerproc.}
proc reraiseException() {.compilerproc.}

proc registerSignalHandler() {.compilerproc.}

proc chckIndx(i, a, b: int): int {.inline, compilerproc.}
proc chckRange(i, a, b: int): int {.inline, compilerproc.}
proc chckRangeF(x, a, b: float): float {.inline, compilerproc.}
proc chckNil(p: pointer) {.inline, compilerproc.}

type
  PSafePoint = ptr TSafePoint
  TSafePoint {.compilerproc.} = record
    prev: PSafePoint # points to next safe point ON THE STACK
    exc: ref E_Base
    status: int
    context: C_JmpBuf

var
  excHandler {.compilerproc, volatile.}: PSafePoint = nil
    # list of exception handlers
    # a global variable for the root of all try blocks

proc reraiseException() =
  if excHandler != nil:
    raise newException(ENoExceptionToReraise, "no exception to reraise")
  else:
    c_longjmp(excHandler.context, 1)

type
  PFrame = ptr TFrame
  TFrame {.importc, nodecl.} = record
    prev: PFrame
    procname: CString
    line: int # current line number
    filename: CString
    len: int  # length of slots (when not debugging always zero)

  TTempFrame = record # used for recursion elimination in WriteStackTrace
    procname: CString
    line: int

var
  buf: string       # cannot be allocated on the stack!
  assertBuf: string # we need a different buffer for
                    # assert, as it raises an exception and
                    # exception handler needs the buffer too

  framePtr {.exportc, volatile.}: PFrame

  tempFrames: array [0..255, TTempFrame] # cannot be allocated
                                         # on the stack!

proc auxWriteStackTrace(f: PFrame, s: var string) =
  var
    it = f
    i = 0
    total = 0
  while it != nil and i <= high(tempFrames):
    tempFrames[i].procname = it.procname
    tempFrames[i].line = it.line
    inc(i)
    inc(total)
    it = it.prev
  while it != nil:
    inc(total)
    it = it.prev
  # if the buffer overflowed print '...':
  if total != i:
    add(s, "(")
    add(s, $(total-i))
    add(s, " calls omitted) ...\n")
  for j in countdown(i-1, 0):
    add(s, $tempFrames[j].procname)
    if tempFrames[j].line > 0:
      add(s, ", line: ")
      add(s, $tempFrames[j].line)
    add(s, "\n")

proc rawWriteStackTrace(s: var string) =
  if framePtr == nil:
    add(s, "No stack traceback available\n")
  else:
    add(s, "Traceback (most recent call last)\n")
    auxWriteStackTrace(framePtr, s)

proc quitOrDebug() {.inline.} =
  when not defined(emdb):
    quit(1)
  else:
    emdbStep() # call the debugger

proc raiseException(e: ref E_Base, ename: CString) =
  GC_disable() # a bad thing is an error in the GC while raising an exception
  e.name = ename
  if excHandler != nil:
    excHandler.exc = e
    c_longjmp(excHandler.context, 1)
  else:
    if cast[pointer](buf) != nil:
      setLen(buf, 0)
      rawWriteStackTrace(buf)
      if e.msg != nil and e.msg[0] != '\0':
        add(buf, "Error: unhandled exception: ")
        add(buf, $e.msg)
      else:
        add(buf, "Error: unhandled exception")
      add(buf, " [")
      add(buf, $ename)
      add(buf, "]\n")
      writeToStdErr(buf)
    else:
      writeToStdErr("*** FATAL ERROR *** ")
      writeToStdErr(ename)
      writeToStdErr("\n")
    quitOrDebug()
  GC_enable()

var
  gAssertionFailed: ref EAssertionFailed

proc internalAssert(file: cstring, line: int, cond: bool) {.compilerproc.} =
  if not cond:
    GC_disable() # BUGFIX: `$` allocates a new string object!
    if cast[pointer](assertBuf) != nil: # BUGFIX: when debugging the GC, assertBuf may be nil
      setLen(assertBuf, 0)
      add(assertBuf, "[Assertion failure] file: ")
      add(assertBuf, file)
      add(assertBuf, " line: ")
      add(assertBuf, $line)
      add(assertBuf, "\n")
      gAssertionFailed.msg = assertBuf
    GC_enable()
    raise gAssertionFailed # newException(EAssertionFailed, assertBuf)

proc WriteStackTrace() =
  var
    s: string = ""
  rawWriteStackTrace(s)
  writeToStdErr(s)

var
  dbgAborting: bool # whether the debugger wants to abort

proc signalHandler(sig: cint) {.exportc: "signalHandler", noconv.} =
  # print stack trace and quit
  var
    s = int(sig)
  setLen(buf, 0)
  rawWriteStackTrace(buf)

  if s == SIGINT: add(buf, "SIGINT: Interrupted by Ctrl-C.\n")
  elif s == SIGSEGV: add(buf, "SIGSEGV: Illegal storage access.\n")
  elif s == SIGABRT:
    if dbgAborting: return # the debugger wants to abort
    add(buf, "SIGABRT: Abnormal termination.\n")
  elif s == SIGFPE: add(buf, "SIGFPE: Arithmetic error.\n")
  elif s == SIGILL: add(buf, "SIGILL: Illegal operation.\n")
  elif s == SIGBUS: add(buf, "SIGBUS: Illegal storage access.\n")
  else: add(buf, "unknown signal\n")
  writeToStdErr(buf)
  dbgAborting = True # play safe here...
  quit(1) # always quit when SIGABRT

proc registerSignalHandler() =
  c_signal(SIGINT, signalHandler)
  c_signal(SIGSEGV, signalHandler)
  c_signal(SIGABRT, signalHandler)
  c_signal(SIGFPE, signalHandler)
  c_signal(SIGILL, signalHandler)
  c_signal(SIGBUS, signalHandler)

registerSignalHandler() # call it in initialization section 
# for easier debugging of the GC, this memory is only allocated after the 
# signal handlers have been registered
new(gAssertionFailed)
buf = newString(2048)
assertBuf = newString(2048)
setLen(buf, 0)
setLen(assertBuf, 0)

proc raiseRangeError() {.compilerproc, noreturn.} =
  raise newException(EOutOfRange, "value out of range")

proc raiseIndexError() {.compilerproc, noreturn.} =
  raise newException(EInvalidIndex, "index out of bounds")

proc chckIndx(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseIndexError()

proc chckRange(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError()

proc chckRange64(i, a, b: int64): int64 {.compilerproc.} =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError()

proc chckRangeF(x, a, b: float): float =
  if x >= a and x <= b:
    return x
  else:
    raiseRangeError()

proc chckNil(p: pointer) =
  if p == nil: c_raise(SIGSEGV)

proc chckObj(obj, subclass: PNimType) {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return # optimized fast path
  while x != subclass:
    if x == nil:
      raise newException(EInvalidObjectConversion, "invalid object conversion")
    x = x.base

proc chckObjAsgn(a, b: PNimType) {.compilerproc, inline.} =
  if a != b:
    raise newException(EInvalidObjectAssignment, "invalid object assignment")
