discard """
  output: '''HELLO WORLD
c_func'''
"""

import macros, strutils

emit("echo " & '"' & "hello world".toUpper & '"')

# bug #1025

macro foo(icname): stmt =
  let ic = newStrLitNode($icname)
  result = quote do:
    proc x* =
      proc private {.exportc: `ic`.} = discard
      echo `ic`
      private()

foo(c_func)
x()
