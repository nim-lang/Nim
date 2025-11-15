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
when defined(nimPreviewSlimSystem):
  import std/formatfloat

proc raiseRangeError(val: BiggestInt) {.compilerproc, noinline.} =
  when hostOS == "standalone":
    sysFatal(RangeDefect, "value out of range")
  else:
    sysFatal(RangeDefect, "value out of range: ", $val)

proc raiseIndexError4(l1, h1, h2: int) {.compilerproc, noinline.} =
  when defined(runtimeDebug):
    var msg = "Slice Out of Bounds [IndexDefect]\n"
    msg.add "  attempted slice: " & $l1 & ".." & $h1 & "\n"
    msg.add "  container bounds: 0.." & $(h2 - 1) & "\n"
    msg.add "  container length: " & $h2 & "\n"
    if l1 < 0:
      msg.add "  error: slice start " & $l1 & " is negative\n"
    if h1 >= h2:
      msg.add "  error: slice end " & $h1 & " exceeds container (max: " & $(h2-1) & ")\n"
    msg.add "\nhelp: ensure slice is within container bounds\n"
    msg.add "  | let safeEnd = min(sliceEnd, container.len - 1)\n"
    msg.add "  | let safeStart = max(sliceStart, 0)\n"
    sysFatal(IndexDefect, msg)
  else:
    sysFatal(IndexDefect, "index out of bounds: " & $l1 & ".." & $h1 & " notin 0.." & $(h2 - 1))

proc raiseIndexError3(i, a, b: int) {.compilerproc, noinline.} =
  when defined(runtimeDebug):
    # Enhanced error message with detailed context
    var msg = "Index Out of Bounds [IndexDefect]\n"
    if b < a:
      msg.add "  attempted to access index " & $i & " of an empty container\n"
      msg.add "  valid range is empty (invalid bounds)\n"
    else:
      msg.add "  attempted index: " & $i & "\n"
      msg.add "  valid range: " & $a & ".." & $b & "\n"
      if i > b:
        let excess = i - b
        msg.add "  excess: +" & $excess & " beyond maximum\n"
      elif i < a:
        let excess = a - i
        msg.add "  excess: -" & $excess & " below minimum\n"
    msg.add "\nhelp: validate index is within bounds\n"
    msg.add "  | if idx >= " & $a & " and idx <= " & $b & ":\n"
    msg.add "  |   # safe to access\n"
    msg.add "  | else:\n"
    msg.add "  |   # handle out of bounds\n"
    sysFatal(IndexDefect, msg)
  else:
    sysFatal(IndexDefect, formatErrorIndexBound(i, a, b))

proc raiseIndexError2(i, n: int) {.compilerproc, noinline.} =
  when defined(runtimeDebug):
    # Enhanced error message with detailed context
    var msg = "Index Out of Bounds [IndexDefect]\n"
    if n == 0:
      msg.add "  attempted to access index " & $i & " of an empty container\n"
    else:
      msg.add "  attempted index: " & $i & "\n"
      msg.add "  valid range: 0.." & $(n-1) & "\n"
      msg.add "  container length: " & $n & "\n"
      if i >= n:
        let excess = i - n + 1
        msg.add "  excess: +" & $excess & " beyond last valid index\n"
      else:
        let excess = -i
        msg.add "  excess: " & $excess & " (negative index)\n"
    msg.add "\nhelp: add bounds checking before accessing\n"
    msg.add "  | if idx >= 0 and idx < container.len:\n"
    msg.add "  |   result = container[idx]\n"
    msg.add "  | else:\n"
    msg.add "  |   # handle error\n"
    sysFatal(IndexDefect, msg)
  else:
    sysFatal(IndexDefect, formatErrorIndexBound(i, n))

proc raiseIndexError() {.compilerproc, noinline.} =
  sysFatal(IndexDefect, "index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noinline.} =
  ## remove after bootstrap > 1.5.1
  when defined(runtimeDebug):
    var msg = "Invalid Field Access [FieldDefect]\n"
    msg.add "  " & f & "\n"
    msg.add "\nThis happens when:\n"
    msg.add "  - Accessing a field that is not valid for the current discriminant value\n"
    msg.add "  - Variant object is in a different state than expected\n"
    msg.add "\nhelp: check discriminant value before accessing variant fields\n"
    msg.add "  | case obj.kind\n"
    msg.add "  | of kindA:\n"
    msg.add "  |   # access fields valid for kindA\n"
    msg.add "  | of kindB:\n"
    msg.add "  |   # access fields valid for kindB\n"
    sysFatal(FieldDefect, msg)
  else:
    sysFatal(FieldDefect, f)

when defined(nimV2):
  proc raiseFieldError2(f: string, discVal: int) {.compilerproc, noinline.} =
    ## raised when field is inaccessible given runtime value of discriminant
    when defined(runtimeDebug):
      var msg = "Invalid Field Access [FieldDefect]\n"
      msg.add "  " & f & $discVal & "'\n"
      msg.add "  discriminant value: " & $discVal & "\n"
      msg.add "\nThe field you're trying to access is not valid for the current discriminant value.\n"
      msg.add "\nhelp: check the discriminant before accessing variant fields\n"
      msg.add "  | if obj.kind == correctKind:\n"
      msg.add "  |   # access field safely\n"
      sysFatal(FieldDefect, msg)
    else:
      sysFatal(FieldDefect, f & $discVal & "'")

  proc raiseFieldErrorStr(f: string, discVal: string) {.compilerproc, noinline.} =
    ## raised when field is inaccessible given runtime value of discriminant
    when defined(runtimeDebug):
      var msg = "Invalid Field Access [FieldDefect]\n"
      msg.add "  " & formatFieldDefect(f, discVal) & "\n"
      msg.add "  discriminant value: " & discVal & "\n"
      msg.add "\nThe field you're trying to access is not valid for the current discriminant value.\n"
      msg.add "\nhelp: check the discriminant before accessing variant fields\n"
      msg.add "  | case obj.kind\n"
      msg.add "  | of validKind:\n"
      msg.add "  |   # access field safely\n"
      sysFatal(FieldDefect, msg)
    else:
      sysFatal(FieldDefect, formatFieldDefect(f, discVal))
else:
  proc raiseFieldError2(f: string, discVal: string) {.compilerproc, noinline.} =
    ## raised when field is inaccessible given runtime value of discriminant
    when defined(runtimeDebug):
      var msg = "Invalid Field Access [FieldDefect]\n"
      msg.add "  " & formatFieldDefect(f, discVal) & "\n"
      msg.add "  discriminant value: " & discVal & "\n"
      msg.add "\nThe field you're trying to access is not valid for the current discriminant value.\n"
      msg.add "\nhelp: check the discriminant before accessing variant fields\n"
      msg.add "  | case obj.kind\n"
      msg.add "  | of validKind:\n"
      msg.add "  |   # access field safely\n"
      sysFatal(FieldDefect, msg)
    else:
      sysFatal(FieldDefect, formatFieldDefect(f, discVal))

proc raiseRangeErrorI(i, a, b: BiggestInt) {.compilerproc, noinline.} =
  when defined(standalone):
    sysFatal(RangeDefect, "value out of range")
  elif defined(runtimeDebug):
    var msg = "Value Out of Range [RangeDefect]\n"
    msg.add "  attempted value: " & $i & "\n"
    msg.add "  valid range: " & $a & ".." & $b & "\n"
    if i > b:
      let excess = i - b
      msg.add "  excess: +" & $excess & " beyond maximum\n"
    else:
      let excess = a - i
      msg.add "  excess: -" & $excess & " below minimum\n"
    msg.add "\nhelp: clamp value to valid range\n"
    msg.add "  | let clamped = max(" & $a & ", min(value, " & $b & "))\n"
    msg.add "\nhelp: or validate before assignment\n"
    msg.add "  | if value >= " & $a & " and value <= " & $b & ":\n"
    msg.add "  |   result = value\n"
    msg.add "  | else:\n"
    msg.add "  |   raise newException(ValueError, \"out of range\")\n"
    sysFatal(RangeDefect, msg)
  else:
    sysFatal(RangeDefect, "value out of range: " & $i & " notin " & $a & " .. " & $b)

proc raiseRangeErrorF(i, a, b: float) {.compilerproc, noinline.} =
  when defined(standalone):
    sysFatal(RangeDefect, "value out of range")
  elif defined(runtimeDebug):
    var msg = "Float Value Out of Range [RangeDefect]\n"
    msg.add "  attempted value: " & $i & "\n"
    msg.add "  valid range: " & $a & ".." & $b & "\n"
    if i > b:
      let excess = i - b
      msg.add "  excess: +" & $excess & " beyond maximum\n"
    else:
      let excess = a - i
      msg.add "  excess: -" & $excess & " below minimum\n"
    msg.add "\nhelp: clamp float value to valid range\n"
    msg.add "  | let clamped = max(" & $a & ", min(value, " & $b & "))\n"
    sysFatal(RangeDefect, msg)
  else:
    sysFatal(RangeDefect, "value out of range: " & $i & " notin " & $a & " .. " & $b)

proc raiseRangeErrorU(i, a, b: uint64) {.compilerproc, noinline.} =
  when defined(runtimeDebug):
    var msg = "Unsigned Value Out of Range [RangeDefect]\n"
    msg.add "  attempted value: " & $i & "\n"
    msg.add "  valid range: " & $a & ".." & $b & "\n"
    if i > b:
      let excess = i - b
      msg.add "  excess: +" & $excess & " beyond maximum\n"
    else:
      let excess = a - i
      msg.add "  excess: " & $excess & " below minimum\n"
    msg.add "\nhelp: validate unsigned value before use\n"
    msg.add "  | if value >= " & $a & " and value <= " & $b & ":\n"
    msg.add "  |   # safe to use\n"
    sysFatal(RangeDefect, msg)
  else:
    sysFatal(RangeDefect, "value out of range")

proc raiseRangeErrorNoArgs() {.compilerproc, noinline.} =
  sysFatal(RangeDefect, "value out of range")

proc raiseObjectConversionError() {.compilerproc, noinline.} =
  when defined(runtimeDebug):
    var msg = "Invalid Object Conversion [ObjectConversionDefect]\n"
    msg.add "  attempted to convert object to incompatible type\n"
    msg.add "\nThis happens when:\n"
    msg.add "  - Downcasting to a type that is not in the inheritance hierarchy\n"
    msg.add "  - Object is not actually an instance of the target type\n"
    msg.add "\nhelp: use runtime type checking before conversion\n"
    msg.add "  | if obj of TargetType:\n"
    msg.add "  |   let converted = TargetType(obj)\n"
    msg.add "  | else:\n"
    msg.add "  |   # handle incompatible type\n"
    sysFatal(ObjectConversionDefect, msg)
  else:
    sysFatal(ObjectConversionDefect, "invalid object conversion")

proc chckIndx(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    result = 0
    raiseIndexError3(i, a, b)

proc chckRange(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    result = 0
    raiseRangeError(i)

proc chckRange64(i, a, b: int64): int64 {.compilerproc.} =
  if i >= a and i <= b:
    return i
  else:
    result = 0
    raiseRangeError(i)

proc chckRangeU(i, a, b: uint64): uint64 {.compilerproc.} =
  if i >= a and i <= b:
    return i
  else:
    result = 0
    sysFatal(RangeDefect, "value out of range")

proc chckRangeF(x, a, b: float): float =
  if x >= a and x <= b:
    return x
  else:
    result = 0.0
    when hostOS == "standalone":
      sysFatal(RangeDefect, "value out of range")
    else:
      sysFatal(RangeDefect, "value out of range: ", $x)

proc chckNil(p: pointer) =
  if p == nil:
    when defined(runtimeDebug):
      var msg = "Nil Dereference [NilAccessDefect]\n"
      msg.add "  attempted to write to a nil pointer\n"
      msg.add "  pointer address: nil (0x0)\n"
      msg.add "\nhelp: check for nil before dereferencing\n"
      msg.add "  | if ptr != nil:\n"
      msg.add "  |   ptr[] = value\n"
      msg.add "  | else:\n"
      msg.add "  |   # handle nil case\n"
      msg.add "\nhelp: consider using Option types\n"
      msg.add "  | import std/options\n"
      msg.add "  | var opt: Option[T] = some(value)\n"
      sysFatal(NilAccessDefect, msg)
    else:
      sysFatal(NilAccessDefect, "attempt to write to a nil address")

proc chckNilDisp(p: pointer) {.compilerproc.} =
  if p == nil:
    when defined(runtimeDebug):
      var msg = "Nil Dispatcher [NilAccessDefect]\n"
      msg.add "  attempted method dispatch on nil object\n"
      msg.add "  object reference: nil\n"
      msg.add "\nThis usually happens when:\n"
      msg.add "  - Calling a method on an uninitialized ref object\n"
      msg.add "  - Object constructor/initialization failed\n"
      msg.add "  - Reference was explicitly set to nil\n"
      msg.add "\nhelp: ensure object is initialized before calling methods\n"
      msg.add "  | if obj != nil:\n"
      msg.add "  |   obj.method()\n"
      msg.add "  | else:\n"
      msg.add "  |   # initialize obj first\n"
      sysFatal(NilAccessDefect, msg)
    else:
      sysFatal(NilAccessDefect, "cannot dispatch; dispatcher is nil")

when not defined(nimV2):

  proc chckObj(obj, subclass: PNimType) {.compilerproc.} =
    # checks if obj is of type subclass:
    var x = obj
    if x == subclass: return # optimized fast path
    while x != subclass:
      if x == nil:
        sysFatal(ObjectConversionDefect, "invalid object conversion")
      x = x.base

  proc chckObjAsgn(a, b: PNimType) {.compilerproc, inline.} =
    if a != b:
      sysFatal(ObjectAssignmentDefect, "invalid object assignment")

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
                      cache: var ObjCheckCache): bool {.compilerproc, inline.} =
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

when defined(nimV2):
  proc raiseObjectCaseTransition() {.compilerproc.} =
    sysFatal(FieldDefect, "assignment to discriminant changes object branch")
