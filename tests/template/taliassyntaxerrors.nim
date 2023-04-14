discard """
  cmd: "nim check --hints:off $file"
"""

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
