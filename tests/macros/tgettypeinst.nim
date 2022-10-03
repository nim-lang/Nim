discard """
"""

import macros

proc symToIdent(x: NimNode): NimNode =
  case x.kind:
    of nnkCharLit..nnkUInt64Lit:
      result = newNimNode(x.kind)
      result.intVal = x.intVal
    of nnkFloatLit..nnkFloat64Lit:
      result = newNimNode(x.kind)
      result.floatVal = x.floatVal
    of nnkStrLit..nnkTripleStrLit:
      result = newNimNode(x.kind)
      result.strVal = x.strVal
    of nnkIdent, nnkSym:
      result = newIdentNode($x)
    else:
      result = newNimNode(x.kind)
      for c in x:
        result.add symToIdent(c)

# check getTypeInst and getTypeImpl for given symbol x
macro testX(x,inst0: typed; recurse: static[bool]; implX: typed) =
  # check that getTypeInst(x) equals inst0
  let inst = x.getTypeInst
  let instr = inst.symToIdent.treeRepr
  let inst0r = inst0.symToIdent.treeRepr
  if instr != inst0r:
    echo "instr:\n", instr
    echo "inst0r:\n", inst0r
    doAssert(instr == inst0r)

  # check that getTypeImpl(x) is correct
  #  if implX is nil then compare to inst0
  #  else we expect implX to be a type definition
  #       and we extract the implementation from that
  let impl = x.getTypeImpl
  var impl0 =
    if implX.kind == nnkNilLit: inst0
    else: implX[0][2]
  let implr = impl.symToIdent.treerepr
  let impl0r = impl0.symToIdent.treerepr
  if implr != impl0r:
    echo "implr:\n", implr
    echo "impl0r:\n", impl0r
    doAssert(implr == impl0r)

  result = newStmtList()
  #template echoString(s: string) = echo s.replace("\n","\n  ")
  #result.add getAst(echoString("  " & inst0.repr))
  #result.add getAst(echoString("  " & inst.repr))
  #result.add getAst(echoString("  " & impl0.repr))
  #result.add getAst(echoString("  " & impl.repr))

  if recurse:
    # now test using a newly formed variable of type getTypeInst(x)
    template testDecl(n,m: typed) =
      testV(n, false):
        type _ = m
    result.add getAst(testDecl(inst.symToIdent, impl.symToIdent))

# test with a variable (instance) of type
template testV(inst, recurse, impl) =
  block:
    #echo "testV(" & astToStr(inst) & ", " & $recurse & "):" & astToStr(impl)
    var x: inst
    testX(x, inst, recurse, impl)

# test with a newly created typedesc (myType)
# using the passed type as the implementation
template testT(impl, recurse) =
  block:
    type myType = impl
    testV(myType, recurse):
      type _ = impl

# test a built-in type whose instance is equal to the implementation
template test(inst) =
  testT(inst, false)
  testV(inst, true, nil)

# test a custom type with provided implementation
template test(inst, impl) =
  testV(inst, true, impl)

type
  Model = object of RootObj
  User = object of Model
    name : string
    password : string

  Tree = object of RootObj
    value : int
    left,right : ref Tree

  MyEnum = enum
    valueA, valueB, valueC

  MySet = set[MyEnum]
  MySeq = seq[int]
  MyIntPtr = ptr int
  MyIntRef = ref int

  GenericObject[T] = object
    value:T
  Foo[N:static[int],T] = object
  Bar[N:static[int],T] = object
    #baz:Foo[N+1,GenericObject[T]]  # currently fails
    baz:Foo[N,GenericObject[T]]

  Generic[T] = seq[int]
  Concrete = Generic[int]

  Generic2[T1, T2] = seq[T1]
  Concrete2 = Generic2[int, float]

  Alias1 = float
  Alias2 = Concrete
  Alias3 = Concrete2

  Vec[N: static[int],T] = object
    arr: array[N,T]
  Vec4[T] = Vec[4,T]


test(bool)
test(char)
test(int)
test(float)
test(ptr int)
test(ref int)
test(array[1..10,Bar[2,Foo[3,float]]])
test(array[MyEnum,Bar[2,Foo[3,float]]])
test(distinct Bar[2,Foo[3,float]])
test(tuple[a:int,b:Foo[-1,float]])
test(seq[int])
test(set[MyEnum])
test(proc (a: int, b: Foo[2,float]))
test(proc (a: int, b: Foo[2,float]): Bar[3,int])

test(MyEnum):
  type _ = enum
    valueA, valueB, valueC
test(Bar[2,Foo[3,float]]):
  type _ = object
    baz: Foo[2, GenericObject[Foo[3, float]]]
test(Model):
  type _ = object of RootObj
test(User):
  type _ = object of Model
    name: string
    password: string
test(Tree):
  type _ = object of RootObj
    value: int
    left: ref Tree
    right: ref Tree
test(Concrete):
  type _ = seq[int]
test(Generic[int]):
  type _ = seq[int]
test(Generic[float]):
  type _ = seq[int]
test(Concrete2):
  type _ = seq[int]
test(Generic2[int,float]):
  type _ = seq[int]
test(Alias1):
  type _ = float
test(Alias2):
  type _ = seq[int]
test(Alias3):
  type _ = seq[int]
test(Vec[4,float32]):
  type _ = object
    arr: array[0..3,float32]
test(Vec4[float32]):
  type _ = object
    arr: array[0..3,float32]

# bug #4862
static:
  discard typedesc[(int, int)].getTypeImpl

# custom pragmas
template myAttr() {.pragma.}
template myAttr2() {.pragma.}
template myAttr3() {.pragma.}
template serializationKey(key: string) {.pragma.}

type
  MyObj {.packed,myAttr,serializationKey: "one".} = object
    myField {.myAttr2,serializationKey: "two".}: int
    myField2 {.myAttr3,serializationKey: "three".}: float

# field pragmas not currently supported
test(MyObj):
  type
    _ {.packed,myAttr,serializationKey: "one".} = object
      myField: int
      myField2: float

block t9600:
  type
    Apple = ref object of RootObj

  macro mixer(x: typed): untyped =
    let w = getType(x)
    let v = getTypeImpl(w[1])

  var z: Apple
  mixer(z)
