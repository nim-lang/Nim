discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout:
'''
tdefaultfieldscheck.nim(14, 17) Error: type mismatch: got <string> but expected 'int'
tdefaultfieldscheck.nim(14, 17) Error: string literal must be of some string type
'''
"""

type
  Date* = object
    goal: float = 7
    name: int = "string"

echo default(Date)
