discard """
  output: '''
only accepts A
only accepts B
only accepts A
only accepts B
'''
"""

# bug #11125: overload resolution with symbols produced by a typed macro arg
import macros

type
  A = ref object of RootObj
  B = ref object of A

proc f(T: typedesc[A], x: A) =
  echo "only accepts A"

proc f(T: typedesc[B], x: B) =
  echo "only accepts B"

macro genCallToF(t: typed, x: untyped): untyped =
  result = newCall(ident "f", [t, newCall(t, x)])

let x1 = A()
let x2 = B()

f(A, A(x1))
f(B, B(x2))

genCallToF(A, x1)
genCallToF(B, x2)
