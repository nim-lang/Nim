discard """
  output: "Got: 'nnkCall' hi"
"""

import
  macros, strutils

macro outterMacro*(n: stmt): stmt {.immediate.} =
  let n = callsite()
  var j : string = "hi"
  proc innerProc(i: int): string =
    echo "Using arg ! " & n.repr
    result = "Got: '" & $n.kind & "' " & $j
  var callNode = n[0]
  expectKind(n, TNimrodNodeKind.nnkCall)
  if n.len != 3 or n[1].kind != TNimrodNodeKind.nnkIdent:
    error("Macro " & callNode.repr &
      " requires the ident passed as parameter (eg: " & callNode.repr &
      "(the_name_you_want)): statements.")
  result = newNimNode(TNimrodNodeKind.nnkStmtList)
  var ass : NimNode = newNimNode(nnkAsgn)
  ass.add(newIdentNode(n[1].ident))
  ass.add(newStrLitNode(innerProc(4)))
  result.add(ass)

var str: string
outterMacro(str):
  "hellow"
echo str


