discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout: '''
tdotopserrors1.nim(15, 7) Error: undeclared field: 'x' for type tdotopserrors1.Bar [type declared in tdotopserrors1.nim(12, 6)]
'''
"""

{.experimental: "dotOperators".}
type Foo = object
template `.`(a: Foo, b: untyped): untyped = 123
type Bar = object
  x1: int
var b: Bar
echo b.x
