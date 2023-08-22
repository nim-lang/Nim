discard """
  errormsg: "The Foo type requires the following fields to be initialized: bar, baz"
  line: "17"
"""
{.experimental: "notnil".}
# bug #2355
type
  Base = object of RootObj
    baz: ref int not nil

  Foo = object of Base
    foo: ref int
    bar: ref int not nil

var x: ref int = new(int)
# Create instance without initializing the `bar` field
var f = Foo(foo: x)
echo f.bar.isNil # true
