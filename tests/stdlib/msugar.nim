import std/sugar

type Bar = object
  x: int
type Foo = object
  bar: Bar

var foo*: Foo
byAddr: barx*=foo.bar.x
