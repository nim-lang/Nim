import t9578

proc testSeq*(x: var seq[mytype]) =
  f(x[0].addr)

proc testSeq2*(x: var ptr seq[mytype]) =
  f(x[0].addr)
