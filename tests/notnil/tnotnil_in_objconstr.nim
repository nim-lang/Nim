discard """
  errormsg: "fields not initialized: bar"
  line: "13"
"""
{.experimental: "notnil".}
# bug #2355
type
  Foo = object
    foo: ref int
    bar: ref int not nil
var x: ref int = new(int)
# Create instance without initializing the `bar` field
var f = Foo(foo: x)
echo f.bar.isNil # true
