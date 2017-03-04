discard """
"""

import macros, strUtils

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

macro testX(x,inst0: typed; recurse: static[bool]; implX: stmt): typed =
  let inst = x.getTypeInst
  let impl = x.getTypeImpl
  let inst0r = inst0.symToIdent.treeRepr
  let instr = inst.symToIdent.treeRepr
  #echo inst0r
  #echo instr
  doAssert(instr == inst0r)
  var impl0 =
    if implX.kind == nnkNilLit: inst0
    else: implX[0][2]
  let impl0r = impl0.symToIdent.treerepr
  let implr = impl.symToIdent.treerepr
  #echo impl0r
  #echo implr
  doAssert(implr == impl0r)
  template echoString(s:string) = echo s.replace("\n","\n  ")
  result = newStmtList()
  #result.add getAst(echoString("  " & inst0.repr))
  #result.add getAst(echoString("  " & inst.repr))
  #result.add getAst(echoString("  " & impl0.repr))
  #result.add getAst(echoString("  " & impl.repr))
  if recurse:
    template testDecl(n, m :typed) =
      testV(n, false):
        type _ = m
    result.add getAst(testDecl(inst.symToIdent, impl.symToIdent))

template testV(inst, recurse, impl) =
  block:
    #echo "testV(" & astToStr(inst) & ", " & $recurse & "):" & astToStr(impl)
    var x: inst
    testX(x, inst, recurse, impl)
template testT(inst, recurse) =
  block:
    type myType = inst
    testV(myType, recurse):
      type _ = inst

template test(inst) =
  testT(inst, false)
  testV(inst, true, nil)
template test(inst, impl) = testV(inst, true, impl)

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
    #baz:Foo[N+1,GenericObject[T]]
    baz:Foo[N,GenericObject[T]]

test(bool)
test(char)
test(int)
test(float)
test(ptr int)
test(ref int)
test(array[1..10,Bar[2,Foo[3,float]]])
test(distinct Bar[2,Foo[3,float]])
test(tuple[a:int,b:Foo[-1,float]])
#test(MyEnum):
#  type _ = enum
#    valueA, valueB, valueC
test(set[MyEnum])
test(seq[int])
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
test(proc (a: int, b: Foo[2,float]))
test(proc (a: int, b: Foo[2,float]): Bar[3,int])

# bug #4862
static:
  discard typedesc[(int, int)].getTypeImpl
