type Bar = object
  x: int
type Foo = object
  bar: Bar

const exportEnabled* = false

when exportEnabled:
  import std/sugar
  var foo*: Foo
  byAddr: barx*=foo.bar.x
