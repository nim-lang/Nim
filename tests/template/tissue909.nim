import macros

template baz() =
  proc bar() =
    var x = 5
    iterator foo(): int {.closure.} =
      echo x
    var y = foo
    discard y()

macro test(): stmt =
  result = getAst(baz())
  echo(treeRepr(result))

test()
bar()
