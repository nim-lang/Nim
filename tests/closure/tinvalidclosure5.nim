discard """
  errormsg: "type mismatch: obtained <proc (){.closure, gcsafe, locks: 0.}> expected 'A = proc (){.nimcall.}'"
  line: 9
"""

type A = proc() {.nimcall.}
proc main =
  let b = 1
  let a: A = proc() = echo b

