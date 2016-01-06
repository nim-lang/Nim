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

  GenericObject[T] = object
    value:T

  Tree = object of RootObj
    value : int
    left,right : ref Tree

  MyEnum = enum
    valueA, valueB, valueC

  TupleType = tuple[a:int,b:float]

  GenericTriple[T] = tuple[a,b,c:T]
  Pair[T,U] = tuple[first:T, second:U]
  Banana[T] = Pair[T,T]

  MyIntA = distinct int
  MyIntB = distinct int
  MyIntC[T] = distinct int
  IntAlias = int

macro testGetType(exp: typed): expr =
  echo "testGetType(" & exp.repr & "):"
  return newLit(exp.repr & ": " & exp.getType2.repr)


var
  a: Model
  b: User
  c: GenericObject[string]
  d: Tree
  e: MyEnum
  f: TupleType
  g: GenericTriple[int]
  h: GenericTriple[float]
  i: Pair[int,float]
  j: Banana[string]
  k: MyIntA
  l: MyIntB
  m: MyIntC[TupleType]
  n: IntAlias
  o: seq[int]
  p: seq[float]
  q: seq[GenericTriple[int]]
  r: distinct int

echo testGetType(a)
echo testGetType(b)
echo testGetType(c)
echo testGetType(d)
echo testGetType(e)
echo testGetType(f)
echo testGetType(g)
echo testGetType(h)
echo testGetType(i)
echo testGetType(j)
echo testGetType(k)
echo testGetType(l)
echo testGetType(m)
echo testGetType(n)
echo testGetType(o)
echo testGetType(r)


