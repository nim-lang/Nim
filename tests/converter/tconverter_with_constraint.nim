
discard """
  errormsg: "type mismatch: got <int>"
  file: "tconverter_with_constraint.nim"
  line: 20
"""

type
  MyType = distinct int

converter to_mytype(m: int{lit}): MyType =
  m.MyType

proc myproc(m: MyType) =
  echo m.int, ".MyType"

myproc(1) # call by literal is ok

var x: int = 12
myproc(x) # should fail
