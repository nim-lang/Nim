#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Dominik Picheta, Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an interface to Nimrod's runtime type information.
## Note that even though ``TAny`` and its operations hide the nasty low level
## details from its clients, it remains inherently unsafe!

# XXX raw pointer needs to be exposed somehow?

include "system/hti.nim"

type
  TAnyKind* = enum      ## what kind of ``any`` it is
    akNone = 0,         ## invalid any
    akBool = 1,         ## any represents a ``bool``
    akChar = 2,         ## any represents a ``char``
    akEnum = 14,        ## any represents an enum
    akArray = 16,       ## any represents an array
    akObject = 17,      ## any represents an object
    akTuple = 18,       ## any represents a tuple
    akSet = 19,         ## any represents a set
    akRange = 20,       ## any represents a range
    akPtr = 21,         ## any represents a ptr
    akRef = 22,         ## any represents a ref
    akSequence = 24,    ## any represents a sequence
    akProc = 25,        ## any represens a proc
    akPointer = 26,     ## any represens a pointer
    akString = 28,      ## any represens a string
    akCString = 29,     ## any represens a cstring
    akInt = 31,         ## any represens an int
    akInt8 = 32,        ## any represens an int8
    akInt16 = 33,       ## any represens an int16
    akInt32 = 34,       ## any represens an int32
    akInt64 = 35,       ## any represens an int64
    akFloat = 36,       ## any represens a float
    akFloat32 = 37,     ## any represens a float32
    akFloat64 = 38,     ## any represens a float64
    akFloat128 = 39,    ## any represens a float128
    akPureObject = 40   ## any represens an object has no `type` field

  TAny* = object {.pure.} ## can represent any nimrod value; NOTE: the wrapped
                          ## value can be modified with its wrapper! This means
                          ## that ``TAny`` keeps a non-traced pointer to its
                          ## wrapped value and MUST not live longer than its
                          ## wrapped value.
    value: pointer
    rawType: PNimType

  ppointer = ptr pointer
  pbyteArray = ptr array[0.. 0xffff, byte]

  TGenSeq {.pure.} = object
    len, space: int
  PGenSeq = ptr TGenSeq

const
  GenericSeqSize = (2 * sizeof(int))

proc genericAssign(dest, src: Pointer, mt: PNimType) {.importc.}

proc getDiscriminant(aa: Pointer, n: ptr TNimNode): int =
  assert(n.kind == nkCase)
  var d: int
  var a = cast[TAddress](aa)
  case n.typ.size
  of 1: d = ze(cast[ptr int8](a +% n.offset)[])
  of 2: d = ze(cast[ptr int16](a +% n.offset)[])
  of 4: d = int(cast[ptr int32](a +% n.offset)[])
  else: assert(false)
  return d

proc selectBranch(aa: Pointer, n: ptr TNimNode): ptr TNimNode =
  var discr = getDiscriminant(aa, n)
  if discr <% n.len:
    result = n.sons[discr]
    if result == nil: result = n.sons[n.len]
    # n.sons[n.len] contains the ``else`` part (but may be nil)
  else:
    result = n.sons[n.len]

proc newAny(value: pointer, rawType: PNimType): TAny =
  result.value = value
  result.rawType = rawType

proc toAny*[T](x: var T): TAny {.inline.} =
  ## constructs a ``TAny`` object from `x`. This captures `x`'s address, so
  ## `x` can be modified with its ``TAny`` wrapper! The client needs to ensure
  ## that the wrapper DOES NOT live longer than `x`!
  result.value = addr(x)
  result.rawType = cast[PNimType](getTypeInfo(x))
  
proc getKind*(x: TAny): TAnyKind {.inline.} = 
  ## get the type kind
  result = TAnyKind(ord(x.rawType.kind))

proc skipRange(x: PNimType): PNimType {.inline.} =
  result = x
  if result.kind == tyRange: result = result.base

template `+!!`(a, b: expr): expr = cast[pointer](cast[TAddress](a) + b)

proc `[]`*(x: TAny, i: int): TAny =
  ## accessor for an any `x` that represents an array or a sequence.
  case x.rawType.kind
  of tyArray:
    var bs = x.rawType.base.size
    if i >% (x.rawType.size div bs - 1): 
      raise newException(EInvalidIndex, "index out of bounds")
    return newAny(x.value +!! i*bs, x.rawType.base)
  of tySequence:
    var s = cast[ppointer](x.value)[]
    var bs = x.rawType.base.size
    if i >% (cast[PGenSeq](s).len-1):
      raise newException(EInvalidIndex, "index out of bounds")
    return newAny(s +!! (GenericSeqSize+i*bs), x.rawType.base)
  else: assert false

proc `[]=`*(x: TAny, i: int, y: TAny) =
  ## accessor for an any `x` that represents an array or a sequence.
  case x.rawType.kind
  of tyArray:
    var bs = x.rawType.base.size
    if i >% (x.rawType.size div bs - 1): 
      raise newException(EInvalidIndex, "index out of bounds")
    assert y.rawType == x.rawType.base
    genericAssign(x.value +!! i*bs, y.value, y.rawType)
  of tySequence:
    var s = cast[ppointer](x.value)[]
    var bs = x.rawType.base.size
    if i >% (cast[PGenSeq](s).len-1):
      raise newException(EInvalidIndex, "index out of bounds")
    assert y.rawType == x.rawType.base
    genericAssign(s +!! (GenericSeqSize+i*bs), y.value, y.rawType)
  else: assert false

proc len*(x: TAny): int =
  ## len for an any `x` that represents an array or a sequence.
  case x.rawType.kind
  of tyArray: result = x.rawType.size div x.rawType.base.size
  of tySequence: result = cast[PGenSeq](cast[ppointer](x.value)[]).len
  else: assert false

proc fieldsAux(p: pointer, n: ptr TNimNode,
               ret: var seq[tuple[name: cstring, any: TAny]]) =
  case n.kind
  of nkNone: assert(false)
  of nkSlot:
    ret.add((n.name, newAny(p +!! n.offset, n.typ)))
    assert ret[ret.len()-1][0] != nil
  of nkList:
    for i in 0..n.len-1: fieldsAux(p, n.sons[i], ret)
  of nkCase:
    var m = selectBranch(p, n)
    ret.add((n.name, newAny(p +!! n.offset, n.typ)))
    if m != nil: fieldsAux(p, m, ret)

iterator fields*(x: TAny): tuple[name: string, any: TAny] =
  ## iterates over every active field of the any `x` that represents an object
  ## or a tuple.
  assert x.rawType.kind in {tyTuple, tyPureObject, tyObject}
  var p = x.value
  var t = x.rawType
  if x.rawType.kind == tyObject: t = cast[ptr PNimType](x.value)[]
  var n = t.node
  var ret: seq[tuple[name: cstring, any: TAny]] = @[]
  fieldsAux(p, n, ret)
  for name, any in items(ret):
    yield ($name, any)

proc `[]`*(x: TAny): TAny =
  ## dereference operation for the any `x` that represents a ptr or a ref.
  assert x.rawtype.kind in {tyRef, tyPtr}
  result.value = cast[ppointer](x.value)[]
  result.rawType = x.rawType.base

proc `[]=`*(x, y: TAny) =
  ## dereference operation for the any `x` that represents a ptr or a ref.
  assert x.rawtype.kind in {tyRef, tyPtr}
  assert y.rawType == x.rawType.base
  genericAssign(cast[ppointer](x.value)[], y.value, y.rawType)

proc getInt*(x: TAny): int =
  ## retrieve the int value out of `x`. `x` needs to represent an int.
  assert skipRange(x.rawtype).kind == tyInt
  result = cast[ptr int](x.value)[]

proc getInt8*(x: TAny): int8 = 
  ## retrieve the int8 value out of `x`. `x` needs to represent an int8.
  assert skipRange(x.rawtype).kind == tyInt8
  result = cast[ptr int8](x.value)[]

proc getInt16*(x: TAny): int16 = 
  ## retrieve the int16 value out of `x`. `x` needs to represent an int16.
  assert skipRange(x.rawtype).kind == tyInt16
  result = cast[ptr int16](x.value)[]
  
proc getInt32*(x: TAny): int32 = 
  ## retrieve the int32 value out of `x`. `x` needs to represent an int32.
  assert skipRange(x.rawtype).kind == tyInt32
  result = cast[ptr int32](x.value)[]

proc getInt64*(x: TAny): int64 = 
  ## retrieve the int64 value out of `x`. `x` needs to represent an int64.
  assert skipRange(x.rawtype).kind == tyInt64
  result = cast[ptr int64](x.value)[]

proc getBiggestInt*(x: TAny): biggestInt =
  ## retrieve the integer value out of `x`. `x` needs to represent
  ## some integer, a bool, a char or an enum. The value might be
  ## sign-extended to ``biggestInt``.
  var t = skipRange(x.rawtype)
  case t.kind
  of tyInt: result = biggestInt(cast[ptr int](x.value)[])
  of tyInt8: result = biggestInt(cast[ptr int8](x.value)[])
  of tyInt16: result = biggestInt(cast[ptr int16](x.value)[])
  of tyInt32: result = biggestInt(cast[ptr int32](x.value)[])
  of tyInt64: result = biggestInt(cast[ptr int64](x.value)[])
  of tyBool: result = biggestInt(cast[ptr bool](x.value)[])
  of tyChar: result = biggestInt(cast[ptr char](x.value)[])
  of tyEnum:
    case t.size
    of 1: result = ze64(cast[ptr int8](x.value)[])
    of 2: result = ze64(cast[ptr int16](x.value)[])
    of 4: result = biggestInt(cast[ptr int32](x.value)[])
    of 8: result = biggestInt(cast[ptr int64](x.value)[])
    else: assert false
  else: assert false

proc getChar*(x: TAny): char =
  ## retrieve the char value out of `x`. `x` needs to represent a char.
  var t = skipRange(x.rawtype)
  assert t.kind == tyChar
  result = cast[ptr char](x.value)[]

proc getBool*(x: TAny): bool =
  ## retrieve the bool value out of `x`. `x` needs to represent a bool.
  var t = skipRange(x.rawtype)
  assert t.kind == tyBool
  result = cast[ptr bool](x.value)[]

proc getEnumField*(x: TAny): string =
  ## gets the enum field name as a string. `x` needs to represent an enum.
  var typ = skipRange(x.rawtype)
  assert typ.kind == tyEnum
  var e = int(getBiggestInt(x))
  if ntfEnumHole notin typ.flags:
    if e <% typ.node.len:
      return $typ.node.sons[e].name
  else:
    # ugh we need a slow linear search:
    var n = typ.node
    var s = n.sons
    for i in 0 .. n.len-1:
      if s[i].offset == e: return $s[i].name
  result = $e & " (invalid data!)"

proc getFloat*(x: TAny): float = 
  ## retrieve the float value out of `x`. `x` needs to represent an float.  
  assert skipRange(x.rawtype).kind == tyFloat
  result = cast[ptr float](x.value)[]

proc getFloat32*(x: TAny): float32 = 
  ## retrieve the float32 value out of `x`. `x` needs to represent an float32.
  assert skipRange(x.rawtype).kind == tyFloat64
  result = cast[ptr float32](x.value)[]
  
proc getFloat64*(x: TAny): float64 = 
  ## retrieve the float64 value out of `x`. `x` needs to represent an float64.
  assert skipRange(x.rawtype).kind == tyFloat64
  result = cast[ptr float64](x.value)[]

proc getBiggestFloat*(x: TAny): biggestFloat =
  ## retrieve the float value out of `x`. `x` needs to represent
  ## some float. The value is extended to ``biggestFloat``.
  case skipRange(x.rawtype).kind
  of tyFloat: result = biggestFloat(cast[ptr Float](x.value)[])
  of tyFloat32: result = biggestFloat(cast[ptr Float32](x.value)[])
  of tyFloat64: result = biggestFloat(cast[ptr Float64](x.value)[])
  else: assert false

proc getString*(x: TAny): string = 
  ## retrieve the string value out of `x`. `x` needs to represent a string.
  assert x.rawtype.kind == tyString
  result = cast[ptr string](x.value)[]

proc assign*(x, y: TAny) = 
  ## copies the value of `y` to `x`. The assignment operator for ``TAny``
  ## does NOT do this; it performs a shallow copy instead!
  assert y.rawType == x.rawType
  genericAssign(x.value, y.value, y.rawType)

iterator elements*(x: TAny): int =
  ## iterates over every element of `x` that represents a Nimrod bitset.
  assert x.rawType.kind == tySet
  var typ = x.rawtype
  var p = x.value
  # "typ.slots.len" field is for sets the "first" field
  var u: int64
  case typ.size
  of 1: u = ze64(cast[ptr int8](p)[])
  of 2: u = ze64(cast[ptr int16](p)[])
  of 4: u = ze64(cast[ptr int32](p)[])
  of 8: u = cast[ptr int64](p)[]
  else:
    var a = cast[pbyteArray](p)
    for i in 0 .. typ.size*8-1:
      if (ze(a[i div 8]) and (1 shl (i mod 8))) != 0:
        yield i+typ.node.len
  if typ.size <= 8:
    for i in 0..sizeof(int64)*8-1:
      if (u and (1'i64 shl int64(i))) != 0'i64:
        yield i+typ.node.len

proc inclSetElement*(x: TAny, elem: int) =
  ## includes an element `elem` in `x`. `x` needs to represent a Nimrod bitset.
  assert x.rawType.kind == tySet
  var typ = x.rawtype
  var p = x.value
  # "typ.slots.len" field is for sets the "first" field
  var e = elem - typ.node.len
  case typ.size
  of 1:
    var a = cast[ptr int8](p)
    a[] = a[] or (1'i8 shl int8(e))
  of 2:
    var a = cast[ptr int16](p)
    a[] = a[] or (1'i16 shl int16(e))
  of 4: 
    var a = cast[ptr int32](p)
    a[] = a[] or (1'i32 shl int32(e))
  of 8:
    var a = cast[ptr int64](p)
    a[] = a[] or (1'i64 shl e)
  else:
    var a = cast[pbyteArray](p)
    a[e div 8] = toU8(a[e div 8] or (1 shl (e mod 8)))

when isMainModule:
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

  var test = @[0,1,2,3,4]
  var x = toAny(test)
  var y = 78
  x[4] = toAny(y)
  assert cast[ptr int](x[2].value)[] == 2
  
  var test2: tuple[name: string, s: int] = ("test", 56)
  var x2 = toAny(test2)
  var i = 0
  for n, a in fields(x2):
    case i
    of 0: assert n == "name" and $a.getKind == "akString"
    of 1: assert n == "s" and $a.getKind == "akInt"
    else: assert false
    inc i
    
  var test3: TestObj
  test3.test = 42
  test3.test2 = blah2
  var x3 = toAny(test3)
  i = 0
  for n, a in fields(x3):
    case i
    of 0: assert n == "test" and $a.getKind == "akInt" 
    of 1: assert n == "asd" and $a.getKind == "akInt"
    of 2: assert n == "test2" and $a.getKind == "akEnum"
    else: assert false
    inc i
  
  var test4: ref string
  new(test4)
  test4[] = "test"
  var x4 = toAny(test4)
  assert($x4[].getKind() == "akString")
