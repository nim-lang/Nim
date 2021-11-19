discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout: '''
tcallopserrors.nim(16, 2) Error: attempting to call routine: 'b'
  found 'b' [var declared in tcallopserrors.nim(15, 5)]
'''
"""

{.experimental: "callOperator".}
type Foo = object
template `()`(a: Foo, b: untyped, c: untyped) = echo "something"
type Bar = object
  x1: int
var b: Bar
b(123)
