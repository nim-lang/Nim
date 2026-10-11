discard """
  targets: "c cpp js"
  output: '''
B
B
A
B
B
'''
"""

# bug #4320: a method used as a proc value must dispatch
from std/sequtils import map

type
  A = ref object of RootObj
  B = ref object of A

method returnself(a: A): A {.base.} = echo "A"; return a
method returnself(b: B): A = echo "B"; return b

var bees: seq[A] = @[]
bees.add B()
bees.add B()

discard map(bees, returnself)

proc viaBase(x: A) = discard procCall returnself(x)
viaBase(bees[0])

let f: proc (a: A): A {.nimcall.} = returnself
discard f(bees[0])
discard map(bees[0..0], proc (a: A): A = a.returnself)
