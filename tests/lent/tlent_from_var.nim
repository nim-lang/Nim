discard """
  output: "x"
"""

# bug #14805

type Foo = object
  a: string

proc bar(f: var Foo): lent string =
  result = f.a

var foo = Foo(a: "x")
echo bar(foo)
