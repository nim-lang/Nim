# issue #7974

import macros

macro genTypeA(arg: typed): untyped =
  if arg.typeKind != ntyTypeDesc:
    error("expected typedesc", arg)

  result = arg.getTypeInst[1]

macro genTypeB(arg: typed): untyped =
  if arg.typeKind != ntyTypeDesc:
    error("expected typedesc", arg)


  let typeSym = arg.getTypeInst[1]
  result =
    nnkTupleTy.newTree(
      nnkIdentDefs.newTree(
        ident"a", typeSym, newEmptyNode()
      )
    )

type
  # this is the trivial case, MyTypeA[T] is basically just T, nothing else. But it works.
  MyTypeA[T] = genTypeA(T)
  # in this case I generate `tuple[a: T]`. This this is something the compiler does not want
  MyTypeB[T] = genTypeB(T)

# these are just alias types for int32 and float32, nothing really happens, but it works
var a1: MyTypeA[int32]
doAssert a1 is MyTypeA[int32]
doAssert a1 is int32
a1 = 0'i32
var a2: MyTypeA[float32]
doAssert a2 is MyTypeA[float32]
doAssert a2 is float32
a2 = 0'f32
var a3: MyTypeA[float32]
doAssert a3 is MyTypeA[float32]
doAssert a3 is float32
a3 = 0'f32

var b1: MyTypeB[int32]   # cannot generate VM code fur tuple[a: int32]
doAssert b1 is MyTypeB[int32]
doAssert b1 is tuple[a: int32]
b1 = (a: 0'i32)
var b2: MyTypeB[float32]
doAssert b2 is MyTypeB[float32]
doAssert b2 is tuple[a: float32]
b2 = (a: 0'f32)
var b3: MyTypeB[float32]
doAssert b3 is MyTypeB[float32]
doAssert b3 is tuple[a: float32]
b3 = (a: 0'f32)
