discard """
  output: "100"
"""

# bug #8459: generic param of a param's type used in the return type
type
  Foo[T] = object
    a: T
  Bar[T] = object
    b: T

proc doThing(foo: Foo): Bar[foo.T] =
  result.b = foo.a

var foo: Foo[int]
foo.a = 100
let what = doThing(foo)
echo what.b
