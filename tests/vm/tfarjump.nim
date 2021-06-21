# Test a VM relative jump with an offset larger then 32767 instructions.

import macros

static:
  var a = 0
  macro foo(): untyped =
    let s = newStmtList()
    for i in 1..6554:
      s.add nnkCommand.newTree(ident("inc"), ident("a"))
    quote do:
      if true:
        `s`
  foo()
