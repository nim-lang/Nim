import macros

macro makeEnum(): untyped =
  newTree(nnkEnumTy, newEmptyNode(), ident"a", ident"b", ident"c")

macro makeObject(): untyped =
  newTree(nnkObjectTy, newEmptyNode(), newEmptyNode(), newTree(nnkRecList,
    newTree(nnkIdentDefs, ident"x", ident"y", ident"int", newEmptyNode())))

type
  Foo = makeEnum()
  Bar = makeObject()

doAssert {a, b, c} is set[Foo]
let bar = Bar(x: 3, y: 4)
doAssert (bar.x, bar.y) == (3, 4)
