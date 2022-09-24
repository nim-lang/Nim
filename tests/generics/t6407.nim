discard """
action: compile
"""

proc foo[T6407: SomeFloat](y: T6407):int = 0

proc foo[T6407: SomeInteger](y: T6407):int = 1

proc boo[T6407](x: T6407):int =
  foo[T6407](x)

doAssert boo(1) == 1