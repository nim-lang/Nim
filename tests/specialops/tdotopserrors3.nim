discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout: '''
tdotopserrors3.nim(15, 2) Error: undeclared field: 'x' for type tdotopserrors3.Bar [type declared in tdotopserrors3.nim(17, 6)]
'''
"""

{.experimental: "dotOperators".}
type Foo = object
template `.=`(a: Foo, b: untyped, c: untyped) = b = c
type Bar = object
  x1: int
var b: Bar
b.x = 123
