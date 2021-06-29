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
100
0 4
'''
"""

block:
  type Foo = object
  var a: Foo
  template `.`(a: Foo, b: untyped): untyped = astToStr(b)
  template callme(a, f): untyped = a.f
  doAssert callme(a, f2) == "f2" # not `f`
  doAssert a.callme(f3) == "f3"

type
  T1 = object
    x*: int

  TD = distinct T1

  T2 = object
    x: int

template `.`*(v: T1, f: untyped): int =
  echo "reading field ", astToStr(f)
  v.x

template `.=`(t: var T1, f: untyped, v: int) =
  echo "assigning ", astToStr(f), " = ", v
  t.x = v

template `.()`(x: T1, f: untyped, args: varargs[typed]): string =
  echo "call to ", astToStr(f)
  "dot call"

echo ""

var t = T1(x: 10)

echo t.x
t.z = 20
echo t.y
echo t.y()

var d = TD(t)
assert(not compiles(d.y))

template `.`(v: T2, f: untyped): int =
  echo "no params call to ", astToStr(f)
  v.x

template `.`*(v: T2, f: untyped, a: int): int =
  echo "one param call to ", astToStr(f), " with ", a
  v.x

var tt = T2(x: 100)

echo tt.a
echo tt.b()
echo tt.c(10)

assert(not compiles(tt.d("x")))
assert(not compiles(tt.d(1, 2)))

# test simple usage that delegates fields:
type
  Other = object
    a: int
    b: string
  MyObject = object
    nested: Other
    x, y: int

template `.`(x: MyObject; field: untyped): untyped =
  x.nested.field

template `.=`(x: MyObject; field, value: untyped) =
  x.nested.field = value

var m: MyObject

m.a = 4
m.b = "foo"
echo m.x, " ", m.a
