discard """
  output: '''
something
something
foo2
foo3
foo4
'''
"""

# bug #3833, #5043: passing a `void` generic parameter on
proc bar[T](x: T): string =
  "something"

proc foo[T](x: T) =
  echo bar(x)

foo[void]()

proc baz[T](a: int; x: T; b: int) =
  doAssert a + b == 3
  echo bar(x)

baz[void](1, 2)

# bug #5043
proc foo2[T](t: T) = echo "foo2"
proc foo3() = echo "foo3"
proc foo4(t: void) = echo "foo4"

proc bar2[T](t: T) =
  foo2[void](t)
  foo3(t)
  foo4(t)

bar2[void]()
