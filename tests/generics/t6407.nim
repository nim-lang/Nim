discard """
  output: '''
integer
real
bool
int
str
'''
"""

# bug #6407: constraints in explicit instantiations within generics
proc foo[T: SomeFloat](x: T) = echo "real"
proc foo[T: SomeInteger](x: T) = echo "integer"

proc boo[T](x: T) = foo[T](x)
boo(1)
boo(1.0)

proc sort[T: uint8|char|byte](c: T) = echo "u8"
proc sort[T: bool](c: T) = echo "bool"
proc sorted[T](c: T): T =
  sort[T](c)
  c
discard sorted(true)

proc foo2[T: string](x: T) = echo "str"
proc foo2[T: int](x: T) = echo "int"
proc bar[T](x: T) = foo2[T](x)
bar(1)
bar("a")
