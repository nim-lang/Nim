import macros

macro lispReprStr*(a: untyped): untyped = newLit(a.lispRepr)

macro assertAST*(expected: string, struct: untyped): untyped =
  var ast = newLit(struct.treeRepr)
  result = quote do:
    if `ast` != `expected`:
      echo "Got:"
      echo `ast`.indent(2)
      echo "Expected:"
      echo `expected`.indent(2)
      raise newException(ValueError, "Failed to lex properly")

