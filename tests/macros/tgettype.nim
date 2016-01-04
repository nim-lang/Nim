discard """
msg: '''a: object RootObj
b: object Model
  name
  password
c: ref[Tree:ObjectType]
d: enum enum valueA
  valueB, valueC
e: tuple[int, float]
f: tuple[int, int, int]
g: tuple[float, float, float]
h: distinct[int]
i: distinct[int]'''
"""
import macros

type
  Model = object of RootObj
  User = object of Model
    name : string
    password : string

  Tree = ref object of RootObj
    value : int
    left,right : Tree

  MyEnum = enum
    valueA, valueB, valueC

  TupleType = tuple[a:int,b:float]

  GenericTriple[T] = tuple[a,b,c:T]

  MyIntA = distinct int
  MyIntB = distinct int


macro testGetType(exp: typed): expr =
   return newLit($exp & ": " & exp.getType2.repr)

var
  a: Model
  b: User
  c: Tree
  d: MyEnum
  e: TupleType
  f: GenericTriple[int]
  g: GenericTriple[float]
  h: MyIntA
  i: MyIntB

echo testGetType(a)
echo testGetType(b)
echo testGetType(c)
echo testGetType(d)
echo testGetType(e)
echo testGetType(f)
echo testGetType(g)
echo testGetType(h)
echo testGetType(i)
