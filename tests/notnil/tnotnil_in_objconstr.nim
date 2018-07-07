discard """
  errormsg: "fields not initialized: bar"
  line: "13"
"""
{.experimental: "notnil".}
# bug #2355
type
  Foo = object
    foo: string not nil
    bar: string not nil

# Create instance without initializaing the `bar` field
var f = Foo(foo: "foo")
echo f.bar.isNil # true
