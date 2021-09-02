discard """
cmd: '''nim check --hints:off $file'''
action: reject
nimout: '''
tundeclared_field.nim(25, 12) Error: undeclared field: 'bad1' for type tundeclared_field.A [type declared in tundeclared_field.nim(22, 8)]
tundeclared_field.nim(30, 17) Error: undeclared field: 'bad2' for type tundeclared_field.A [type declared in tundeclared_field.nim(28, 8)]
tundeclared_field.nim(36, 4) Error: undeclared field: 'bad3' for type tundeclared_field.A [type declared in tundeclared_field.nim(33, 8)]
tundeclared_field.nim(42, 12) Error: undeclared field: 'bad4' for type tundeclared_field.B [type declared in tundeclared_field.nim(39, 8)]
tundeclared_field.nim(43, 4) Error: undeclared field: 'bad5' for type tundeclared_field.B [type declared in tundeclared_field.nim(39, 8)]
tundeclared_field.nim(44, 23) Error: undeclared field: 'bad6' for type tundeclared_field.B [type declared in tundeclared_field.nim(39, 8)]
tundeclared_field.nim(46, 19) Error: undeclared field: 'bad7' for type tundeclared_field.B [type declared in tundeclared_field.nim(39, 8)]
tundeclared_field.nim(50, 13) Error: cannot instantiate Foo [type declared in tundeclared_field.nim(49, 8)]
'''
"""

#[
xxx in future work, generic instantiations (e.g. `B[int]`) should be shown with their instantiation instead of `tundeclared_field.B`,
maybe using TPreferedDesc.preferResolved or preferMixed
]#
# line 20
block:
  type A = object
    a0: int
  var a: A
  discard a.bad1

block:
  type A = object
    a0: int
  var a = A(bad2: 0)

block:
  type A = object
    a0: int
  var a: A
  a.bad3 = 0

block:
  type B[T] = object
    b0: int
  var b: B[int]
  discard b.bad4
  b.bad5 = 0
  var b2 = B[int](bad6: 0)
  type Bi = B[int]
  var b3 = Bi(bad7: 0)

block:
  type Foo[T: SomeInteger] = object
  var a: Foo[float]
