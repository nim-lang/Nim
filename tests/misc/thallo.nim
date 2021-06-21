discard """
action: compile
"""

# noted this seems to be an old test file designed for manual testing.

import
  os, strutils, macros

type
  TMyEnum = enum
    meA, meB, meC, meD

when true:
  {.hint: "this is the main file".}

proc fac[T](x: T): T =
  # test recursive generic procs
  if x <= 1: return 1
  else: return x.`*`(fac(x-1))

macro macrotest(n: varargs[untyped]): untyped =
  let n = callsite()
  expectKind(n, nnkCall)
  expectMinLen(n, 2)
  result = newNimNode(nnkStmtList, n)
  for i in 2..n.len-1:
    result.add(newCall("write", n[1], n[i]))
  result.add(newCall("writeLine", n[1], newStrLitNode("")))

macro debug(n: untyped): untyped =
  let n = callsite()
  result = newNimNode(nnkStmtList, n)
  for i in 1..n.len-1:
    result.add(newCall("write", newIdentNode("stdout"), toStrLit(n[i])))
    result.add(newCall("write", newIdentNode("stdout"), newStrLitNode(": ")))
    result.add(newCall("writeLine", newIdentNode("stdout"), n[i]))

macrotest(stdout, "finally", 4, 5, "variable", "argument lists")
macrotest(stdout)

#GC_disable()

echo("This was compiled by Nim version " & system.NimVersion)
writeLine(stdout, "Hello", " World", "!")

echo(["a", "b", "c", "d"].len)
for x in items(["What's", "your", "name", "?", ]):
  echo(x)
var `name` = readLine(stdin)
echo("Hi " & thallo.name & "!\n")
debug(name)

var testseq: seq[string] = @[
  "a", "b", "c", "d", "e"
]
echo(repr(testseq))

var dummy = "hello"
echo(substr(dummy, 2, 3))

echo($meC)

# test tuples:
for x, y in items([(1, 2), (3, 4), (6, 1), (5, 2)]):
  echo x
  echo y

proc simpleConst(): int = return 34

# test constant evaluation:
const
  constEval3 = simpleConst()
  constEval = "abc".contains('b')
  constEval2 = fac(7)

echo(constEval3)
echo(constEval)
echo(constEval2)
echo(1.`+`(2))

for i in 2..6:
  for j in countdown(i+4, 2):
    echo(fac(i * j))

when true:
  {.hint: "this is the main file".}
