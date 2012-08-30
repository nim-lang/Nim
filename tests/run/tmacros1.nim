discard """
  output: "Got: 'nnkMacroStmt' hi"
"""

import
  macros, strutils

macro outterMacro*(n: stmt): stmt =
  let n = callsite()
  var j : string = "hi"
  proc innerProc(i: int): string =
    echo "Using arg ! " & n.repr
    result = "Got: '" & $n.kind & "' " & $j
  if n.kind != TNimrodNodeKind.nnkMacroStmt:
    error("Macro " & n[0].repr & " requires a block.")
  var callNode = n[0]
  expectKind(callNode, TNimrodNodeKind.nnkCall)
  if callNode.len != 2 or callNode[1].kind != TNimrodNodeKind.nnkIdent:
    error("Macro " & callNode.repr &
      " requires the ident passed as parameter (eg: " & callNode.repr & 
      "(the_name_you_want)): statements.")
  result = newNimNode(TNimrodNodeKind.nnkStmtList)
  var ass : PNimrodNode = newNimNode(TNimrodNodeKind.nnkAsgn)
  ass.add(newIdentNode(callNode[1].ident))
  ass.add(newStrLitNode(innerProc(4)))
  result.add(ass)

var str: string
outterMacro(str):
  "hellow"
echo str


