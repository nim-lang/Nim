discard """
  nimout: '''
Ident "good"
Ident "good"
'''
  output: "97"
"""

# bug #13662: a NimNode captured by a closure in a macro
import macros
macro extract(ast: untyped): untyped =
  echo ast.treeRepr
  (proc () =
    echo ast.treeRepr
  )()
extract(good)
macro foo(c: static[char]) =
  proc f(): char = c
  if false:
    let unused = f()
  newCall("echo", newLit(ord(c)))
foo('a')
