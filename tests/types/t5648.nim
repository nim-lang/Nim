discard """
output: "ptr Foo"
"""

import typetraits

type Foo = object
  bar*: int

proc main() =
  var f = create(Foo)
  f.bar = 3
  echo f.type.name

  discard realloc(f, 0)

  var g = Foo()
  g.bar = 3

main()

