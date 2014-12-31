discard """
  output: "3\n0"
"""

# https://github.com/Araq/Nim/issues/1789

type
  Foo[N: static[int]] = object

proc bindStaticN[N](foo: Foo[N]) =
  var ar0: array[3, int]
  var ar1: array[N, int]
  var ar2: array[1..N, int]
  var ar3: array[0..(N+10), float]
  echo N

var f: Foo[3]
f.bindStaticN

# case 2

type
  ObjectWithStatic[X, Y: static[int], T] = object
    bar: array[X * Y, T]   # this one works

  AliasWithStatic[X, Y: static[int], T] = array[X * Y, T]

var
  x: ObjectWithStatic[1, 2, int]
  y: AliasWithStatic[2, 3, int]

# case 3

type
  Bar[N: static[int], T] = object
    bar: array[N, T]

proc `[]`*[N, T](f: Bar[N, T], n: range[0..(N - 1)]): T =
  assert high(n) == N-1
  result = f.bar[n]
  
var b: Bar[3, int]
echo b[2]

