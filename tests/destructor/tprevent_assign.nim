discard """
  errormsg: "'=copy' is not available for type <Foo>; requires a copy because it's not the last read of 'otherTree'"
  line: 29
"""

type
  Foo = object
    x: int

proc `=destroy`(f: var Foo) = f.x = 0
proc `=`(a: var Foo; b: Foo) {.error.} # = a.x = b.x
proc `=sink`(a: var Foo; b: Foo) = a.x = b.x

proc createTree(x: int): Foo =
  Foo(x: x)

proc take2(a, b: sink Foo) =
  echo a.x, " ", b.x

proc allowThis() =
  # all these temporary lets are harmless:
  let otherTree = createTree(44)
  let b = otherTree
  let c = b
  take2(createTree(34), c)

proc preventThis() =
  let otherTree = createTree(44)
  let b = otherTree
  take2(createTree(34), otherTree)

allowThis()
preventThis()
