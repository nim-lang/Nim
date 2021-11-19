discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout: '''
tdotopserrors3.nim(20, 5) Error: expression 'x=' cannot be called
tdotopserrors3.nim(20, 2) Error: undeclared field: 'x' for type tdotopserrors3.Bar [type declared in tdotopserrors3.nim(17, 6)]
tdotopserrors3.nim(20, 2) Error: undeclared field: '.' for type tdotopserrors3.Bar [type declared in tdotopserrors3.nim(17, 6)]
tdotopserrors3.nim(20, 2) Error: expression '.' cannot be called
tdotopserrors3.nim(20, 2) Error: expression '' has no type (or is ambiguous)
tdotopserrors3.nim(20, 2) Error: '' cannot be assigned to
'''
"""

# {.experimental: "dotOperators".}
# type Foo = object
# template `.=`(a: Foo, b: untyped, c: untyped) = b = c
type Bar = object
  x1: int
var b: Bar
b.x = 123
