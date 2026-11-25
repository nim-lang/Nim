discard """
  output: '''
5
3
A()
called A with 1
Red(duration: 2)
'''
"""

# a branch name with positional arguments calls a routine of that name;
# `Branch()` and `Branch(field: value)` always construct

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
proc A() = echo "not called"
proc A(x: int) = echo "called A with ", x
echo A()
A(1)
echo Red(duration: 2)
let o: Light = Off()
let k = B(x: 1)
