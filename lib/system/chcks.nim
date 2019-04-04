#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Implementation of some runtime checks.
include system/indexerrors

proc raiseRangeError(val: BiggestInt) {.compilerproc, noinline.} =
  when hostOS == "standalone":
    sysFatal(RangeError, "value out of range")
  else:
    sysFatal(RangeError, "value out of range: ", $val)

proc raiseIndexError3(i, a, b: int) {.compilerproc, noinline.} =
  sysFatal(IndexError, formatErrorIndexBound(i, a, b))

proc raiseIndexError2(i, n: int) {.compilerproc, noinline.} =
  sysFatal(IndexError, formatErrorIndexBound(i, n))

proc raiseIndexError() {.compilerproc, noinline.} =
  sysFatal(IndexError, "index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noinline.} =
  sysFatal(FieldError, f, " is not accessible")

proc chckIndx(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseIndexError3(i, a, b)

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
    when hostOS == "standalone":
      sysFatal(RangeError, "value out of range")
    else:
      sysFatal(RangeError, "value out of range: ", $x)

proc chckNil(p: pointer) =
  if p == nil:
    sysFatal(NilAccessError, "attempt to write to a nil address")

proc chckNilDisp(p: pointer) {.compilerproc.} =
  if p == nil:
    sysFatal(NilAccessError, "cannot dispatch; dispatcher is nil")

when not defined(nimV2):

  proc chckObj(obj, subclass: PNimType) {.compilerproc.} =
    # checks if obj is of type subclass:
    var x = obj
    if x == subclass: return # optimized fast path
    while x != subclass:
      if x == nil:
        sysFatal(ObjectConversionError, "invalid object conversion")
      x = x.base

  proc chckObjAsgn(a, b: PNimType) {.compilerproc, inline.} =
    if a != b:
      sysFatal(ObjectAssignmentError, "invalid object assignment")

  type ObjCheckCache = array[0..1, PNimType]

  proc isObjSlowPath(obj, subclass: PNimType;
                    cache: var ObjCheckCache): bool {.noinline.} =
    # checks if obj is of type subclass:
    var x = obj.base
    while x != subclass:
      if x == nil:
        cache[0] = obj
        return false
      x = x.base
    cache[1] = obj
    return true

  proc isObjWithCache(obj, subclass: PNimType;
                      cache: var ObjCheckCache): bool {.compilerProc, inline.} =
    if obj == subclass: return true
    if obj.base == subclass: return true
    if cache[0] == obj: return false
    if cache[1] == obj: return true
    return isObjSlowPath(obj, subclass, cache)

  proc isObj(obj, subclass: PNimType): bool {.compilerproc.} =
    # checks if obj is of type subclass:
    var x = obj
    if x == subclass: return true # optimized fast path
    while x != subclass:
      if x == nil: return false
      x = x.base
    return true
