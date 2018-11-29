discard """
  errormsg: "cannot call method eval at compile time"
  line: 14
"""

type
  PExpr = ref object of RootObj

method eval(e: PExpr): int =
  discard

static:
  let x = PExpr()
  discard x.eval
