discard """
  matrix: "--implicitStatic:on"
  output: '''
15
144
5
30
8
42
'''
"""

# a call to an inner proc with constant arguments must not be evaluated at
# compile time when the inner proc captures a local of the enclosing routine
proc outer(k: int): int =
  func inner(x: int): int = x * k
  inner(3)
echo outer(5)

func sq(x: int): int = x * x
let a = sq(12)
echo a

proc outer2(): int =
  func inner2(x: int): int = x + 1
  const c = inner2(4)
  c
echo outer2()

# the captured local is mutated through the inner proc
proc outer3(): int =
  var acc = 0
  proc add(x: int) = acc += x
  add(10)
  add(20)
  acc
echo outer3()

# capture from two levels up
proc outer4(k: int): int =
  proc mid(): int =
    func deep(x: int): int = x + k
    deep(1)
  mid()
echo outer4(7)

# a non-capturing inner proc is still folded at compile time
proc outer5(): int =
  func pure(x: int): int = x * 2
  const folded = pure(21)
  static: doAssert folded == 42
  pure(21)
echo outer5()
