discard """
output: '''
############
#### gt ####
############
gt(Foo):	typeDesc[Foo]
gt(Bar):	typeDesc[Bar]
gt(Baz):	typeDesc[int]
gt(foo):	distinct[int]
gt(bar):	distinct[int]
gt(baz):	int, int
gt(v):	seq[int]
gt(vv):	seq[float]
gt(t):	distinct[tuple[int, int]]
gt(tt):	distinct[tuple[float, float]]
gt(s):	distinct[tuple[int, int]]
#############
#### gt2 ####
#############
gt2(Foo): 	Foo
gt2(Bar): 	Bar
gt2(Baz): 	Baz
gt2(foo): 	Foo
gt2(bar): 	Bar
gt2(baz): 	Baz
gt2(v): 	seq[int]
gt2(vv): 	seq[float]
gt2(t): 	MyType[system.int]
gt2(tt): 	MyType[system.float]
gt2(s): 	MySimpleType
'''
"""

import macros, typetraits

type Foo = distinct int
type Bar = distinct int
type Baz = int

let foo = 0.Foo
let bar = 1.Bar
let baz = 2.Baz

type MyType[T] = distinct tuple[a,b:T]
type MySimpleType = distinct tuple[a,b: int]

var v: seq[int]
var vv: seq[float]
var t: MyType[int]
var tt: MyType[float]
var s: MySimpleType

echo "############"
echo "#### gt ####"
echo "############"

macro gt(a: typed): string =
  let b = a.getType
  var str = "gt(" & $a & "):\t" & b.repr
  if b.kind == nnkSym: # bad predicat to check weather the type has an implementation
    str = str & ", " & b.getType.repr  # append the implementation to the result
  result = newLit(str)

echo gt(Foo) # typeDesc[Foo]
echo gt(Bar) # typeDesc[Bar]
echo gt(Baz) # typeDesc[int]     shouldn't it be typeDesc[Baz]?
echo gt(foo) # distinct[int]     I would prefer Foo, distinct[int]
echo gt(bar) # distinct[int]     I would prefer Bar, distinct[int]
echo gt(baz) # int, int          I would prefer Baz, int

echo gt(v)   # seq[int], ok
echo gt(vv)  # seq[float], ok
echo gt(t)   # MyType, distinct[tuple[int, int]]      I would prefer MyType[int],   distinct[tuple[int, int]]
echo gt(tt)  # MyType, distinct[tuple[float, float]]  I would prefer MyType[float], distinct[tuple[int, int]]
echo gt(s)   # distinct[tuple[int, int]]              I would prefer MySimpleType, distinct[tuple[int,int]]

echo "#############"
echo "#### gt2 ####"
echo "#############"

# get type name via typetraits

macro gt2(a: typed): string =
  let prefix = "gt2(" & $a & "): \t"
  result = quote do:
    `prefix` & `a`.type.name

echo gt2(Foo) # Foo  shouldn't this be typeDesc[Foo] ?
echo gt2(Bar) # Bar  shouldn't this be typeDesc[Bar] ?
echo gt2(Baz) # Baz  shouldn't this be typeDesc[Baz] ?
echo gt2(foo) # Foo
echo gt2(bar) # Bar
echo gt2(baz) # Baz

echo gt2(v)   # seq[int]
echo gt2(vv)  # seq[float]
echo gt2(t)   # MyType[system.int]      why is it system.int and not just int like in seq?
echo gt2(tt)  # MyType[system.float]    why is it system.float and not just float like in seq?
echo gt2(s)   # MySimpleType
