discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout: '''
tdotopserrors1.nim(15, 7) Error: expression 'x' cannot be called
'''
"""

{.experimental: "dotOperators".}
type Foo = object
template `.`(a: Foo, b: untyped): untyped = 123
type Bar = object
  x1: int
var b: Bar
echo b.x
