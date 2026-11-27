discard """
  output: "3"
"""

# bug #11161: a discardable call that ends a routine body does not have to
# produce the result
import macros

proc d(x: int): int {.discardable.} = x

proc g(): tuple[a, b: int] =
  result.a = 3
  d(result.a)

doAssert g() == (3, 0)

proc same(): int =
  d(5) # still the result

doAssert same() == 5

macro foo(): untyped =
  proc bar(i: int): tuple[u, v: NimNode] =
    result.u = newStmtList()
    result.u.add newCall(ident"echo", newLit i)
  result = bar(3).u

foo()
