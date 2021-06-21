import t9578

proc testOpenArray*(x: var openArray[mytype]) =
  f(x[0].addr)
