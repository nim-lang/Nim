discard """
  output: '''
10
assigning z = 20
reading field y
20
call to y
dot call
no params call to a
100
no params call to b
100
one param call to c with 10
100'''
"""

type
  T1 = object
    x*: int

  TD = distinct T1

  T2 = object
    x: int

proc `.`*(v: T1, f: string): int =
  echo "reading field ", f
  return v.x

proc `.=`(x: var T1, f: string{lit}, v: int) =
  echo "assigning ", f, " = ", v
  x.x = v

template `.()`(x: T1, f: string, args: varargs[expr]): string =
  echo "call to ", f
  "dot call"

echo ""

var t = T1(x: 10)

echo t.x
t.z = 20
echo t.y
echo t.y()

var d = TD(t)
assert(not compiles(d.y))

proc `.`(v: T2, f: string): int =
  echo "no params call to ", f
  return v.x

proc `.`*(v: T2, f: string, a: int): int =
  echo "one param call to ", f, " with ", a
  return v.x

var tt = T2(x: 100)

echo tt.a
echo tt.b()
echo tt.c(10)

assert(not compiles(tt.d("x")))
assert(not compiles(tt.d(1, 2)))

