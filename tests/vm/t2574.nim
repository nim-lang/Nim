discard """
  line: 14
  errormsg: "cannot call method eval at compile time"
"""

type
  PExpr = ref object of RootObj

method eval(e: PExpr): int =
  discard

static:
  let x = PExpr()
  discard x.eval
