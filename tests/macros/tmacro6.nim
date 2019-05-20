# this is the Nim scratch file
# feel free to try out things
# when done try to run it with `compile'

import macros
# import math
# import strutils
# import sugar
# import sequtils

#var unittestResult = 0

#proc unittestFinalizer(): void {.noconv.} =
#  echo("abc")

#addQuitProc(unittestFinalizer)

proc foo(a,b,c: int): int =
  result += a
  result += b
  result += c

macro bar(a,b,c: int): int =
  result = newCall(ident"echo")
  result.add a
  result.add b
  result.add c

# this is an already existing bug

macro baz(a,b,c: int): int =
  let stmt = nnkStmtListExpr.newTree()
  stmt.add newCall(ident"echo", a)
  stmt.add newCall(ident"echo", b)
  stmt.add newCall(ident"echo", c)
  stmt.add newLit(123)
  return c

proc bar(a: int, b,d: float): void =
  discard

# this should create an error message, because 123 has to be discarded.

macro foobar() =
  result = quote do:
    echo "Hello World"
    123

foobar()
