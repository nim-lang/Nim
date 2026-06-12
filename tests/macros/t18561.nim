discard """
  output: '''done'''
"""
# Issue #18561: modifying typed params in macros (even after copyNimTree) gives SIGSEGV
# https://github.com/nim-lang/Nim/issues/18561

import macros
macro bar(n: typed): untyped =
  var n = n.copyNimTree
  let tmp = genSym(nskLet, "tmp")
  let j = n[1][0][0]
  n[1][0][0] = tmp
  result = quote do:
    let `tmp` = `j`
    let lhs = `n`

type
  A = object
    x: int
  PA = ref A
proc fn(c: int): int = c
let a = PA()
bar(fn(a[].x))

echo "done"
