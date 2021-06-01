discard """
cmd: '''nim check --hints:off $file'''
action: reject
nimout: '''
tundeclared_field.nim(25, 12) Error: undeclared field: 'bad' for type tundeclared_field.A [type declared in tundeclared_field.nim(22, 8)]
tundeclared_field.nim(30, 16) Error: undeclared field: 'bad' for type tundeclared_field.A [type declared in tundeclared_field.nim(28, 8)]
tundeclared_field.nim(36, 4) Error: undeclared field: 'bad' for type tundeclared_field.A [type declared in tundeclared_field.nim(33, 8)]
tundeclared_field.nim(40, 13) Error: cannot instantiate Foo [type declared in tundeclared_field.nim(39, 8)]
'''
"""









# line 20
block:
  type A = object
    a0: int
  var a: A
  discard a.bad

block:
  type A = object
    a0: int
  var a = A(bad: 0)

block:
  type A = object
    a0: int
  var a: A
  a.bad = 0

block:
  type Foo[T: SomeInteger] = object
  var a: Foo[float]
