import macros

macro lispReprStr*(a: untyped): untyped = newLit(a.lispRepr)

macro assertAST*(expected: string, struct: untyped): untyped =
  var ast = newLit(struct.treeRepr)
  result = quote do:
    if `ast` != `expected`:
      doAssert false, "\nGot:\n" & `ast`.indent(2) & "\nExpected:\n" & `expected`.indent(2)