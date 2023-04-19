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

block: # generic template
  type Foo = object
    bar: int

  var foo = Foo(bar: 10)
  template bar[T]: T = T(foo.bar)
  let a = bar #[tt.Error
      ^ invalid type: 'template (): T' for let. Did you mean to call the template with '()'?; tt.Error
          ^ 'bar' has unspecified generic parameters]#
  let b = bar[float]()
  doAssert b == 10.0
  bar = 15 #[tt.Error
  ^ 'bar' cannot be assigned to]#
