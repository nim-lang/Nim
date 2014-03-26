
type
  Foo = object
    a, b: int
    s: string

  Bar {.borrow: `.`.} = distinct Foo

var bb: ref Bar
new bb
bb.a = 90
bb.s = "abc"

