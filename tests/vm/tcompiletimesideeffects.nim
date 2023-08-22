discard """
  output:
'''
@[0, 1, 2]
@[3, 4, 5]
@[0, 1, 2]
3
4
'''
"""

template runNTimes(n: int, f : untyped) : untyped =
  var accum: seq[type(f)]
  for i in 0..n-1:
    accum.add(f)
  accum

var state {.compileTime.} : int = 0
proc fill(): int {.compileTime.} =
  result = state
  inc state

# invoke fill() at compile time as a compile time expression
const C1 = runNTimes(3, fill())
echo C1

# invoke fill() at compile time as a set of compile time statements
const C2 =
  block:
    runNTimes(3, fill())
echo C2

# invoke fill() at compile time after a compile time reset of state
const C3 =
  block:
    state = 0
    runNTimes(3, fill())
echo C3

# evaluate fill() at compile time and use the results at runtime
echo fill()
echo fill()
