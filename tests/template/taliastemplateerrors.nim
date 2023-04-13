discard """
  cmd: "nim check $file"
"""

block:
  var x = 3
  template foo: untyped {.alias.} = x
  var y = 4
  template foo: untyped {.alias.} = y #[tt.Error
  ^ redefinition of 'foo'; previous declaration here: taliastemplateerrors.nim(7, 12)]#
  template foo: untyped {.alias, redefine.} = y
  doAssert foo == y
  proc foo(x: int): int = x + 1 #[tt.Error
       ^ redefinition of 'foo'; previous declaration here: taliastemplateerrors.nim(11, 12)]#

block:
  template minus: untyped {.alias.} = `-`
  discard minus() #[tt.Error
               ^ type mismatch: got <>]#
  block:
    # cannot use if overloaded
    template minus(a, b, c): untyped = a - b - c
    doAssert minus(3, 5, 8) == -10
    discard minus(1) #[tt.Error
                 ^ type mismatch: got <int literal(1)>]#

block: # with params
  type Foo = object
    bar: int

  var foo = Foo(bar: 10)
  template bar(x: int): int = x + foo.bar
  let a = bar #[tt.Error
      ^ invalid type: 'template (x: int): int' for let. Did you mean to call the template with '()'?]#
  bar = 15 #[tt.Error
  ^ 'bar' cannot be assigned to]#

block: # {.noalias.}
  type Foo = object
    bar: int

  var foo = Foo(bar: 10)
  template bar: int {.noalias.} = foo.bar
  let a = bar #[tt.Error
      ^ invalid type: 'template (): int' for let. Did you mean to call the template with '()'?]#
  bar = 15 #[tt.Error
  ^ 'bar' cannot be assigned to]#
