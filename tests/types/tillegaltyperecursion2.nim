discard """
  errormsg: "illegal recursion in type 'Executor'"
  line: 8
"""
# bug reported by PR #5637
type
  Executor[N] = Executor[N]
var e: Executor[int]
