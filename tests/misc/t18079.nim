discard """
  matrix: "--mm:orc"
"""

type
  Foo = object
    y: int

  Bar = object
    x: Foo

proc baz(state: var Bar):int = 
  state.x.y = 2
  state.x.y
doAssert baz((ref Bar)(x: (new Foo)[])[]) == 2
