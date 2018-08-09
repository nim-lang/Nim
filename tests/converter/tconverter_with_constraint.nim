
discard """
  file: "tconverter_with_constraint.nim"
  line: 18
  errormsg: "type mismatch: got <int>"
"""

type
  MyType = distinct int

converter to_mytype(m: int{lit}): MyType =
  m.MyType
 
proc myproc(m: MyType) =
  echo m.int, ".MyType"

var x: int = 12
myproc(x)