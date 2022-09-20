discard """
action: compile
"""

proc foo[T: SomeFloat](x: T) = discard

proc foo[T: SomeInteger](x: T) = discard

proc boo[T](x: T) =
  foo[T](x)

boo(1)