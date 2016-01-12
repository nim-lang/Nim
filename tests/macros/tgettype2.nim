discard """
g:
  tuple[int, float]
  tuple[int, float]
h:
  SimplePair
  tuple[int, float]
i:
  MyPair[int, float]
  tuple[int, float]
j:
  WithFloat[int]
  MyPair[int, float]
k:
  IntWithFloat
  WithFloat[int]
m:
  MyIntA
  distinct[int]
n:
  MyIntB
  distinct[int]
o:
  distinct[int]
  distinct[int]
p:
  MyIntC[SimplePair]
  distinct[int]
q:
  IntAlias
  int
r:
  seq[int]
  seq[int]
s:
  seq[float]
  seq[float]
t:
  seq[WithFloat[int]]
  seq[WithFloat[int]]
u:
  MySet
  set[MyEnum]
v:
  MySeq
  seq[int]
w:
  MyIntPtr
  ptr[int]
x:
  MyIntRef
  ref[int]
foo:
  proc[float, int16, int32]
  proc[float, int16, int32]
set[MyEnum]:
  typeDesc[set[MyEnum]]
  typeDesc[set[MyEnum]]'''
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

  SimplePair = tuple[a:int,b:float]
  MyPair[T,U] = tuple[a:T, b:U]
  WithFloat[T] = MyPair[T,float]
  IntWithFloat = WithFloat[int]

  MyIntA = distinct int
  MyIntB = distinct int
  MyIntC[T] = distinct int
  IntAlias = int

  MySet = set[MyEnum]
  MySeq = seq[int]
  MyIntPtr = ptr int
  MyIntRef = ref int

proc foo(a: int16, b: int32): float = (a*b).float

macro callGetType2(exp: typed): string =
  return exp.getType2.repr

macro callGetTypeImpl(exp: typed): string =
  return exp.getTypeImpl.repr

macro testGetType2(exp: typed): string =
  echo "testGetType(" & exp.repr & "):"
  return exp.repr & ":\n  " & exp.getType2.repr & "\n  " & exp.getTypeImpl.repr

var
  a: Model
  b: User
  c: GenericObject[string]
  d: Tree
  e: MyEnum
  g: tuple[a:int,b:float]
  h: SimplePair        # tuple[a:int,b:float]
  i: MyPair[int,float] # tuple[a:T, b:U]
  j: WithFloat[int]    # MyPair[T,float]
  k: IntWithFloat      # WithFloat[int]
  m: MyIntA
  n: MyIntB
  o: distinct int
  p: MyIntC[SimplePair]
  q: IntAlias
  r: seq[int]
  s: seq[float]
  t: seq[WithFloat[int]]
  u: MySet
  v: MySeq
  w: MyIntPtr
  x: MyIntRef


#echo testGetType2(a)
#echo testGetType2(b)
#echo testGetType2(c)
#echo testGetType2(d)
#echo testGetType2(e)

echo testGetType2(g) # tuple[a:int,b:float]
echo testGetType2(h) # SimplePair = tuple[a:int,b:float]
echo testGetType2(i) # MyPair[int,float] = tuple[a:int, b:float]
echo testGetType2(j) # WithFloat[int]   = MyPair[int,float]
echo testGetType2(k) # IntWithFloat     = WithFloat[int]

echo testGetType2(m) # MyIntA = distinct int
echo testGetType2(n) # MyIntB = distinct int
echo testGetType2(o) # distinct int
echo testGetType2(p) # MyIntC[SimplePair] = distinct int
echo testGetType2(q) # IntAlias = int
echo testGetType2(r) # seq[int]
echo testGetType2(s) # seq[float]
echo testGetType2(t) # seq[GenericTriple[int]]
echo testGetType2(u) # MySet
echo testGetType2(v) # MySeq = seq[int]
echo testGetType2(w) # MyIntPtr = ptr int
echo testGetType2(x) # MyIntRef = ref int
echo testGetType2(foo)
echo testGetType2(set[MyEnum])

