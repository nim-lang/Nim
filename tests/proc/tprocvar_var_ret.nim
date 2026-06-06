discard """
  targets: "c cpp"
"""

proc testVarRet(x: var int): var int = x

proc testProcTypeParam(prc: proc (x: var int): var int {.nimcall.}) = discard

testProcTypeParam(testVarRet)
