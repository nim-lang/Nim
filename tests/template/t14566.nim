discard """
  output: '''
truetrue
10 4 5
'''
"""

# bug #14566: a `static` template parameter in the return type
type
  Arb[N: static int] = pointer
  Bro[N: static int] = Arb[N]
proc getPointer[N: static int]: Bro[N] =
  nil
template foo(size: static uint): Arb[size] =
  getPointer[size]()
let a = foo(10)
template bar(size: static uint): auto =
  getPointer[size]()
let b = bar(10)
echo a == nil, b == nil

type
  Arc[N: static int] = object
    x: array[N, int]
proc getArc[N: static int]: Arc[N] = discard
template foo2(size: static int): Arc[size] =
  getArc[size]()
const k = 4
let a2 = foo2(10)
let b2 = foo2(k)
let c2 = foo2(k+1)
echo a2.x.len, " ", b2.x.len, " ", c2.x.len
