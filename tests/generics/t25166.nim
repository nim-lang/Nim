discard """
output: '''
SomeFloat
SomeFloat
SomeFloat
SomeFloat
'''
"""

# bug #25166

type Obj = ref object of RootObj

proc foo(s: Obj, x: SomeFloat) =
  echo "SomeFloat"
template foo(s: Obj, x: auto) =
  echo "auto"

foo(Obj(), 1.23)

proc bar[T: SomeFloat](s: Obj, x: T) =
  echo "SomeFloat"
proc bar[T](s: Obj, x: T) =
  echo "any"

bar(Obj(), 1.23)

# the following works

proc baz[T: SomeFloat](x: T, s: Obj) =
  echo "SomeFloat"
proc baz[T](x: T, s: Obj) =
  echo "any"

baz(1.23, Obj())

type Obj2 = ref object

proc quz[T: SomeFloat](s: Obj2, x: T) =
  echo "SomeFloat"
proc quz[T](s: Obj2, x: T) =
  echo "any"

quz(Obj2(), 1.23)
