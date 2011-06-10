include "system/hti.nim"

type
  TType* = enum # This mirrors the TNimKind type in hti.nim
    TNNone, TNBool, TNChar,
    TNEmpty, TNArrayConstr, TNNil, TNExpr, TNStmt, TNTypeDesc,
    TNGenericInvokation, # ``T[a, b]`` for types to invoke
    TNGenericBody,       # ``T[a, b, body]`` last parameter is the body
    TNGenericInst,       # ``T[a, b, realInstance]`` instantiated generic type
    TNGenericParam,      # ``a`` in the example
    TNDistinct,          # distinct type
    TNEnum,
    TNOrdinal,
    TNArray,
    TNObject,
    TNTuple,
    TNSet,
    TNRange,
    TNPtr, TNRef,
    TNVar,
    TNSequence,
    TNProc,
    TNPointer, TNOpenArray,
    TNString, TNCString, TNForward,
    TNInt, TNInt8, TNInt16, TNInt32, TNInt64,
    TNFloat, TNFloat32, TNFloat64, TNFloat128,
    TNPureObject # signals that object has no `n_type` field

  TAny* = object {.pure.}
    value: pointer
    rawType: PNimType

  ppointer = ptr pointer

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

proc toAny*[T](x: var T): TAny =
  var k = getTypeInfo(x)
  return newAny(addr(x), cast[PNimType](k))
  
proc getType*(x: TAny): TType = return TType(x.rawType.kind)

proc `[]`*(x: TAny, i: int): TAny =
  assert getType(x) in {TNArray, TNSequence}
  if x.getType == TNArray:
    var bs = x.rawType.base.size
    if i >% (x.rawType.size div bs - 1): 
      raise newException(EInvalidIndex, "Index out of bounds.")
    return newAny(cast[pointer](cast[TAddress](x.value) + i*bs),
                  x.rawType.base)
  elif x.getType == TNSequence:
    var s = cast[ppointer](x.value)[]
    var bs = x.rawType.base.size
    if i >% (cast[PGenSeq](s).len-1):
      raise newException(EInvalidIndex, "Index out of bounds.")
    return newAny(cast[pointer](cast[TAddress](s) + GenericSeqSize+i*bs),
                  x.rawType.base)

proc `[]=`*(x: TAny, i: int, y: TAny) =
  assert getType(x) in {TNArray, TNSequence}
  if x.getType == TNArray:
    var bs = x.rawType.base.size
    if i >% (x.rawType.size div bs - 1): 
          raise newException(EInvalidIndex, "Index out of bounds.")
    genericAssign(cast[pointer](cast[TAddress](x.value) + i*bs),
                  y.value, y.rawType)
  elif x.getType == TNSequence:
    var s = cast[ppointer](x.value)[]
    var bs = x.rawType.base.size
    if i >% (cast[PGenSeq](s).len-1):
      raise newException(EInvalidIndex, "Index out of bounds.")
    genericAssign(cast[pointer](cast[TAddress](s) + GenericSeqSize+i*bs),
                  y.value, y.rawType)

proc fieldsAux(p: pointer, n: ptr TNimNode,
                ret: var seq[tuple[name: cstring, any: TAny]]) =
  case n.kind
  of nkNone: assert(false)
  of nkSlot:
    var tup = (n.name, 
               newAny(cast[pointer](cast[TAddress](p) + n.offset), n.typ))
    ret.add(tup)
    assert ret[ret.len()-1][0] != nil
  of nkList:
    for i in 0..n.len-1:
      fieldsAux(p, n.sons[i], ret)
  of nkCase:
    var m = selectBranch(p, n)
    ret.add((n.name, newAny(cast[pointer](cast[TAddress](p) + n.offset), n.typ)))
    if m != nil: fieldsAux(p, m, ret)

iterator fields*(x: TAny): tuple[name: string, any: TAny] =
  assert getType(x) in {TNTuple, TNPureObject, TNObject}
  var p = x.value
  var t = x.rawType
  if x.getType == TNObject: t = cast[ptr PNimType](x.value)[]
  var n = t.node
  var ret: seq[tuple[name: cstring, any: TAny]] = @[]
  fieldsAux(p, n, ret)
  for name, any in items(ret):
    yield ($name, any)

proc `[]`*(x: TAny): TAny =
  assert getType(x) in {TNRef, TNPtr}
  var p = cast[ppointer](x.value)[]
  if p == nil:
    result.value = nil
    result.rawType = nil
    return
  else:
    result.value = p
    result.rawType = x.rawType.base

proc readInt*(x: TAny): int = cast[ptr int](x.value)[]
proc readInt8*(x: TAny): int8 = cast[ptr int8](x.value)[]
proc readInt16*(x: TAny): int16 = cast[ptr int16](x.value)[]
proc readInt32*(x: TAny): int32 = cast[ptr int32](x.value)[]
proc readInt64*(x: TAny): int64 = cast[ptr int64](x.value)[]

proc readFloat*(x: TAny): float = cast[ptr float](x.value)[]
proc readFloat32*(x: TAny): float32 = cast[ptr float32](x.value)[]
proc readFloat64*(x: TAny): float64 = cast[ptr float64](x.value)[]

proc readString*(x: TAny): string = cast[ptr string](x.value)[]

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
  echo cast[ptr int](x[2].value)[]
  
  var test2: tuple[name: string, s: int] = ("test", 56)
  var x2 = toAny(test2)
  for n, a in fields(x2):
    echo("Name = ", n)
    echo("Any type = ", a.getType)
    
  var test3: TestObj
  test3.test = 42
  test3.test2 = blah2
  var x3 = toAny(test3)
  for n, a in fields(x3):
    echo("Name = ", n)
    echo("Any type = ", a.getType)
  
  
  var test4: ref string
  new(test4)
  test4[] = "test"
  var x4 = toAny(test4)
  echo x4[].getType()
