discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout:
'''
tdefaultfieldscheck.nim(14, 17) Error: type mismatch: got <string> but expected 'int'
tdefaultfieldscheck.nim(15, 20) Error: type mismatch: got <int literal(12)> but expected 'string'
tdefaultfieldscheck.nim(17, 16) Error: type mismatch: got <float64> but expected 'int'
'''
"""

type
  Date* = object
    name: int = "string"
    time: string = 12
    goal: float = 7
    fun: int = 1.4

echo default(Date)