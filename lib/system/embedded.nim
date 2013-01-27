#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Bare-bones implementation of some things for embedded targets.

proc writeToStdErr(msg: CString) = write(stdout, msg)

proc chckIndx(i, a, b: int): int {.inline, compilerproc.}
proc chckRange(i, a, b: int): int {.inline, compilerproc.}
proc chckRangeF(x, a, b: float): float {.inline, compilerproc.}
proc chckNil(p: pointer) {.inline, compilerproc.}

proc pushFrame(s: PFrame) {.compilerRtl, inl, exportc: "nimFrame".} = nil
proc popFrame {.compilerRtl, inl.} = nil

proc setFrame(s: PFrame) {.compilerRtl, inl.} = nil
proc pushSafePoint(s: PSafePoint) {.compilerRtl, inl.} = nil
proc popSafePoint {.compilerRtl, inl.} = nil
proc pushCurrentException(e: ref E_Base) {.compilerRtl, inl.} = nil
proc popCurrentException {.compilerRtl, inl.} = nil

# some platforms have native support for stack traces:
const
  nativeStackTraceSupported = false
  hasSomeStackTrace = false

proc quitOrDebug() {.inline.} =
  quit(1)

proc raiseException(e: ref E_Base, ename: CString) {.compilerRtl.} =
  writeToStdErr(ename)
 
proc reraiseException() {.compilerRtl.} =
  writeToStdErr("reraise not supported")

proc WriteStackTrace() = nil

proc setControlCHook(hook: proc () {.noconv.}) =
  # ugly cast, but should work on all architectures:
  type TSignalHandler = proc (sig: cint) {.noconv.}
  c_signal(SIGINT, cast[TSignalHandler](hook))

proc raiseRangeError(val: biggestInt) {.compilerproc, noreturn, noinline.} =
  writeToStdErr("value out of range")

proc raiseIndexError() {.compilerproc, noreturn, noinline.} =
  writeToStdErr("index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noreturn, noinline.} =
  writeToStdErr("field is not accessible")

proc chckIndx(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseIndexError()

proc chckRange(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError(i)

proc chckRange64(i, a, b: int64): int64 {.compilerproc.} =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError(i)

proc chckRangeF(x, a, b: float): float =
  if x >= a and x <= b:
    return x
  else:
    raise newException(EOutOfRange, "value " & $x & " out of range")

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

proc isObj(obj, subclass: PNimType): bool {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return true # optimized fast path
  while x != subclass:
    if x == nil: return false
    x = x.base
  return true
