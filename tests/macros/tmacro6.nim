discard """
errormsg: "expression '123' is of type 'int literal(123)' and has to be used (or discarded)"
line: 71
"""

import macros

proc foo(a, b, c: int): int =
  result += a
  result += b
  result += c

macro bar(a, b, c: int): int =
  result = newCall(ident"echo")
  result.add a
  result.add b
  result.add c

macro baz(a, b, c: int): int =
  let stmt = nnkStmtListExpr.newTree()
  stmt.add newCall(ident"echo", a)
  stmt.add newCall(ident"echo", b)
  stmt.add newCall(ident"echo", c)
  stmt.add newLit(123)
  return c

# test no result type with explicit return

macro baz2(a, b, c: int) =
  let stmt = nnkStmtListExpr.newTree()
  stmt.add newCall(ident"echo", a)
  stmt.add newCall(ident"echo", b)
  stmt.add newCall(ident"echo", c)
  return stmt

# test explicit void type with explicit return

macro baz3(a, b, c: int): void =
  let stmt = nnkStmtListExpr.newTree()
  stmt.add newCall(ident"echo", a)
  stmt.add newCall(ident"echo", b)
  stmt.add newCall(ident"echo", c)
  return stmt

# test no result type with result variable

macro baz4(a, b, c: int) =
  result = nnkStmtListExpr.newTree()
  result.add newCall(ident"echo", a)
  result.add newCall(ident"echo", b)
  result.add newCall(ident"echo", c)

# test explicit void type with result variable

macro baz5(a, b, c: int): void =
  let result = nnkStmtListExpr.newTree()
  result.add newCall(ident"echo", a)
  result.add newCall(ident"echo", b)
  result.add newCall(ident"echo", c)

macro foobar1(): int =
  result = quote do:
    echo "Hello World"
    1337

echo foobar1()

# this should create an error message, because 123 has to be discarded.

macro foobar2() =
  result = quote do:
    echo "Hello World"
    123

echo foobar2()
