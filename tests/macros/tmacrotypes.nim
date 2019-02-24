discard """
  nimout: '''intProc; ntyProc; proc[int, int, float]; proc (a: int; b: float): int
void; ntyVoid; void; void
int; ntyInt; int; int
proc (); ntyProc; proc[void]; proc ()
voidProc; ntyProc; proc[void]; proc ()'''
"""

import macros

macro checkType(ex: typed; expected: string): untyped =
  echo ex.getTypeInst.repr, "; ", ex.typeKind, "; ", ex.getType.repr, "; ", ex.getTypeImpl.repr

macro checkProcType(fn: typed): untyped =
  let fn_sym = if fn.kind == nnkProcDef: fn[0] else: fn
  echo fn_sym, "; ", fn_sym.typeKind, "; ", fn_sym.getType.repr, "; ", fn_sym.getTypeImpl.repr


proc voidProc = echo "hello"
proc intProc(a: int, b: float): int {.checkProcType.} = 10

checkType(voidProc(), "void")
checkType(intProc(10, 20.0), "int")
checkType(voidProc, "procTy")
checkProcType(voidProc)

# bug #10548
block:
  var c {.compileTime.} = 0

  macro meshImpl(arg: typed): untyped =
    inc c
    result = arg

  type
    Blub = int32
    Mesh = meshImpl(Club)
    Club = Blub

  static: doAssert(c == 1)

# bug #10702
type
  VectorElementType = SomeNumber | bool
  Vec*[N : static[int], T: VectorElementType] = object
    arr*: array[N, T]

type
  Vec4*[T: VectorElementType] = Vec[4,T]
  Vec3*[T: VectorElementType] = Vec[3,T]
  Vec2*[T: VectorElementType] = Vec[2,T]

template vecGen(U:untyped,V:typed):typed=
  ## ``U`` suffix
  ## ``V`` valType
  ##
  type
    `Vec2 U`* {.inject.} = Vec2[V]
    `Vec3 U`* {.inject.} = Vec3[V]
    `Vec4 U`* {.inject.} = Vec4[V]

vecGen(f, float32)

macro foobar(arg: typed): untyped =
  let typ = arg.getTypeInst
  doAssert typ.getImpl[^1].kind == nnkCall

var x: Vec2f

foobar(x)
