discard """
output: '''
10
10
'''
"""

type GA = concept c
  c.a is int

type A = object
  a: int

type AA = object
  case exists: bool
  of true:
    a: int
  else:
    discard

proc print(inp: GA) =
  echo inp.a

let failing = AA(exists: true, a: 10)
let working = A(a:10)
print(working)
print(failing)
