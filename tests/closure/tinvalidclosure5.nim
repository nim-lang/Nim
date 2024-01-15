discard """
  errormsg: "type mismatch: got <proc (){.closure, gcsafe.}> but expected 'A = proc (){.nimcall.}'"
  line: 9
"""

type A = proc() {.nimcall.}
proc main =
  let b = 1
  let a: A = proc() = echo b

