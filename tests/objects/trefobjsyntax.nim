discard """
  output: '''wohoo
baz'''
"""

# Test to ensure the popular 'ref T' syntax works everywhere

type
  Foo = object
    a, b: int
    s: string

  FooBar = object of RootObj
    n, m: string
  Baz = object of FooBar

proc invoke(a: ref Baz) =
  echo "baz"

# check object construction:
let x = (ref Foo)(a: 0, b: 45, s: "wohoo")
echo x.s

var y: ref FooBar = (ref Baz)(n: "n", m: "m")

invoke((ref Baz)(y))

