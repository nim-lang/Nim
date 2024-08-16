discard """
  output: '''fish
fish'''
"""

import macros

block:
  template init(initHook: proc(s: string)) =
    proc dostuff =
      var s = "fish"
      initHook(s)
    dostuff()

  init do(s: string):
    echo s

block:
  macro init(initHook: proc(s: string)) =
    result = newStmtList(
      newProc(name = ident("dostuff"), body = newStmtList(
        newVarStmt(ident("s"), newStrLitNode("fish")),
        newCall(initHook, ident("s"))
      )),
      newCall("dostuff")
    )

  init proc(s: string) =
    echo s
