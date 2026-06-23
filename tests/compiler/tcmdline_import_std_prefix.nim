discard """
  matrix: "-d:nimPreviewSlimSystem --warning:StdPrefix:on --warningAsError:StdPrefix:on --import:std/objectdollar"
  output: "(a: 23, b: 45)"
"""

type Foo = object
  a, b: int

let x = Foo(a: 23, b: 45)
echo x
