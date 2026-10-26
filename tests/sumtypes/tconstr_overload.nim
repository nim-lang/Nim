discard """
  output: '''
5
3
called A
Red(duration: 2)
'''
"""

# branch names are overloadable: routines of the same name stay callable

type
  Light = object
    case
    of Red: duration: int
    of Off: discard
  Expr = object
    case
    of Lit: v: int
    of `+`: a, b: int

proc Off(x: int): int = x + 1
echo Off(4)
echo 1 + 2

type
  K = object
    case
    of A: discard
    of B: x: int
proc A() = echo "called A"
A()
echo Red(duration: 2)
let o: Light = Off()
let k = B(x: 1)
