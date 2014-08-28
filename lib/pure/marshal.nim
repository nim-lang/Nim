#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains procs for serialization and deseralization of 
## arbitrary Nim data structures. The serialization format uses JSON.
##
## **Restriction**: For objects their type is **not** serialized. This means
## essentially that it does not work if the object has some other runtime
## type than its compiletime type:
##
## .. code-block:: nim
## 
##   type 
##     TA = object
##     TB = object of TA
##       f: int
##
##   var
##     a: ref TA
##     b: ref TB
##
##   new(b)
##   a = b
##   echo($$a[]) # produces "{}", not "{f: 0}"

import streams, typeinfo, json, intsets, tables

proc ptrToInt(x: pointer): int {.inline.} =
  result = cast[int](x) # don't skip alignment

proc storeAny(s: Stream, a: TAny, stored: var IntSet) =
  case a.kind
  of akNone: assert false
  of akBool: s.write($getBool(a))
  of akChar: s.write(escapeJson($getChar(a)))
  of akArray, akSequence:
    if a.kind == akSequence and isNil(a): s.write("null")
    else:
      s.write("[")
      for i in 0 .. a.len-1:
        if i > 0: s.write(", ")
        storeAny(s, a[i], stored)
      s.write("]")
  of akObject, akTuple:
    s.write("{")
    var i = 0
    for key, val in fields(a):
      if i > 0: s.write(", ")
      s.write(escapeJson(key))
      s.write(": ")
      storeAny(s, val, stored)
      inc(i)
    s.write("}")
  of akSet:
    s.write("[")
    var i = 0
    for e in elements(a):
      if i > 0: s.write(", ")
      s.write($e)
      inc(i)
    s.write("]")
  of akRange: storeAny(s, skipRange(a), stored)
  of akEnum: s.write(getEnumField(a).escapeJson)
  of akPtr, akRef:
    var x = a.getPointer
    if isNil(x): s.write("null")
    elif stored.containsOrIncl(x.ptrToInt):
      # already stored, so we simply write out the pointer as an int:
      s.write($x.ptrToInt)
    else:
      # else as a [value, key] pair:
      # (reversed order for convenient x[0] access!)
      s.write("[")
      s.write($x.ptrToInt)
      s.write(", ")
      storeAny(s, a[], stored)
      s.write("]")
  of akProc, akPointer, akCString: s.write($a.getPointer.ptrToInt)
  of akString:
    var x = getString(a)
    if isNil(x): s.write("null")
    else: s.write(escapeJson(x))
  of akInt..akInt64, akUInt..akUInt64: s.write($getBiggestInt(a))
  of akFloat..akFloat128: s.write($getBiggestFloat(a))

proc loadAny(p: var JsonParser, a: TAny, t: var Table[BiggestInt, pointer]) =
  case a.kind
  of akNone: assert false
  of akBool: 
    case p.kind
    of jsonFalse: setBiggestInt(a, 0)
    of jsonTrue: setBiggestInt(a, 1)
    else: raiseParseErr(p, "'true' or 'false' expected for a bool")
    next(p)
  of akChar:
    if p.kind == jsonString:
      var x = p.str
      if x.len == 1:
        setBiggestInt(a, ord(x[0]))
        next(p)
        return
    raiseParseErr(p, "string of length 1 expected for a char")
  of akEnum: 
    if p.kind == jsonString:
      setBiggestInt(a, getEnumOrdinal(a, p.str))
      next(p)
      return
    raiseParseErr(p, "string expected for an enum")
  of akArray:
    if p.kind != jsonArrayStart: raiseParseErr(p, "'[' expected for an array")
    next(p)
    var i = 0
    while p.kind != jsonArrayEnd and p.kind != jsonEof:
      loadAny(p, a[i], t)
      inc(i)
    if p.kind == jsonArrayEnd: next(p)
    else: raiseParseErr(p, "']' end of array expected")
  of akSequence:
    case p.kind 
    of jsonNull:
      setPointer(a, nil)
      next(p)
    of jsonArrayStart:
      next(p)
      invokeNewSeq(a, 0)
      var i = 0
      while p.kind != jsonArrayEnd and p.kind != jsonEof:
        extendSeq(a)
        loadAny(p, a[i], t)
        inc(i)
      if p.kind == jsonArrayEnd: next(p)
      else: raiseParseErr(p, "")
    else:
      raiseParseErr(p, "'[' expected for a seq")
  of akObject, akTuple:
    if a.kind == akObject: setObjectRuntimeType(a)
    if p.kind != jsonObjectStart: raiseParseErr(p, "'{' expected for an object")
    next(p)
    while p.kind != jsonObjectEnd and p.kind != jsonEof:
      if p.kind != jsonString: 
        raiseParseErr(p, "string expected for a field name")
      var fieldName = p.str
      next(p)
      loadAny(p, a[fieldName], t)
    if p.kind == jsonObjectEnd: next(p)
    else: raiseParseErr(p, "'}' end of object expected")
  of akSet:
    if p.kind != jsonArrayStart: raiseParseErr(p, "'[' expected for a set")
    next(p)
    while p.kind != jsonArrayEnd and p.kind != jsonEof:
      if p.kind != jsonInt: raiseParseErr(p, "int expected for a set")
      inclSetElement(a, p.getInt.int)
      next(p)
    if p.kind == jsonArrayEnd: next(p)
    else: raiseParseErr(p, "']' end of array expected")
  of akPtr, akRef:
    case p.kind 
    of jsonNull:
      setPointer(a, nil)
      next(p)
    of jsonInt:
      setPointer(a, t[p.getInt])
      next(p)
    of jsonArrayStart:
      next(p)
      if a.kind == akRef: invokeNew(a)
      else: setPointer(a, alloc0(a.baseTypeSize))      
      if p.kind == jsonInt:
        t[p.getInt] = getPointer(a)
        next(p)
      else: raiseParseErr(p, "index for ref type expected")
      loadAny(p, a[], t)
      if p.kind == jsonArrayEnd: next(p)
      else: raiseParseErr(p, "']' end of ref-address pair expected")
    else: raiseParseErr(p, "int for pointer type expected")
  of akProc, akPointer, akCString: 
    case p.kind 
    of jsonNull:
      setPointer(a, nil)
      next(p)
    of jsonInt:
      setPointer(a, cast[pointer](p.getInt.int))
      next(p)
    else: raiseParseErr(p, "int for pointer type expected")
  of akString:
    case p.kind 
    of jsonNull:
      setPointer(a, nil)
      next(p)
    of jsonString:
      setString(a, p.str)
      next(p)
    else: raiseParseErr(p, "string expected")
  of akInt..akInt64, akUInt..akUInt64: 
    if p.kind == jsonInt:
      setBiggestInt(a, getInt(p))
      next(p)
      return
    raiseParseErr(p, "int expected")
  of akFloat..akFloat128:
    if p.kind == jsonFloat:
      setBiggestFloat(a, getFloat(p))
      next(p)
      return
    raiseParseErr(p, "float expected")
  of akRange: loadAny(p, a.skipRange, t)

proc loadAny(s: Stream, a: TAny, t: var Table[BiggestInt, pointer]) =
  var p: JsonParser
  open(p, s, "unknown file")
  next(p)
  loadAny(p, a, t)
  close(p)

proc load*[T](s: Stream, data: var T) =
  ## loads `data` from the stream `s`. Raises `EIO` in case of an error.
  var tab = initTable[BiggestInt, pointer]()
  loadAny(s, toAny(data), tab)

proc store*[T](s: Stream, data: T) =
  ## stores `data` into the stream `s`. Raises `EIO` in case of an error.
  var stored = initIntSet()
  var d: T
  shallowCopy(d, data)
  storeAny(s, toAny(d), stored)

proc `$$`*[T](x: T): string =
  ## returns a string representation of `x`.
  var stored = initIntSet()
  var d: T
  shallowCopy(d, x)
  var s = newStringStream()
  storeAny(s, toAny(d), stored)
  result = s.data

proc to*[T](data: string): T =
  ## reads data and transforms it to a ``T``.
  var tab = initTable[BiggestInt, pointer]()
  loadAny(newStringStream(data), toAny(result), tab)
  
when isMainModule:
  template testit(x: expr) = echo($$to[type(x)]($$x))

  var x: array[0..4, array[0..4, string]] = [
    ["test", "1", "2", "3", "4"], ["test", "1", "2", "3", "4"], 
    ["test", "1", "2", "3", "4"], ["test", "1", "2", "3", "4"], 
    ["test", "1", "2", "3", "4"]]
  testit(x)
  var test2: tuple[name: string, s: uint] = ("tuple test", 56u)
  testit(test2)
  
  type
    TE = enum
      blah, blah2
  
    TestObj = object
      test, asd: int
      case test2: TE
      of blah:
        help: string
      else:
        nil
        
    PNode = ref TNode
    TNode = object
      next, prev: PNode
      data: string

  proc buildList(): PNode =
    new(result)
    new(result.next)
    new(result.prev)
    result.data = "middle"
    result.next.data = "next"
    result.prev.data = "prev"
    result.next.next = result.prev
    result.next.prev = result
    result.prev.next = result
    result.prev.prev = result.next

  var test3: TestObj
  test3.test = 42
  test3.test2 = blah
  testit(test3)

  var test4: ref tuple[a, b: string]
  new(test4)
  test4.a = "ref string test: A"
  test4.b = "ref string test: B"
  testit(test4)
  
  var test5 = @[(0,1),(2,3),(4,5)]
  testit(test5)

  var test6: set[char] = {'A'..'Z', '_'}
  testit(test6)

  var test7 = buildList()
  echo($$test7)
  testit(test7)

  type 
    TA {.inheritable.} = object
    TB = object of TA
      f: int

  var
    a: ref TA
    b: ref TB
  new(b)
  a = b
  echo($$a[]) # produces "{}", not "{f: 0}"

