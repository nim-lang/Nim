discard """
  output: '''@[2, 2, 2, 2, 2]
0'''
"""

# bug #3144

type IntArray[N: static[int]] = array[N, int]

proc `$`(a: IntArray): string = $(@(a))

proc `+=`[N: static[int]](a: var IntArray[N], b: IntArray[N]) =
  for i in 0 .. < N:
    a[i] += b[i]

proc zeros(N: static[int]): IntArray[N] =
  for i in 0 .. < N:
    result[i] = 0

proc ones(N: static[int]): IntArray[N] =
  for i in 0 .. < N:
    result[i] = 1

proc sum[N: static[int]](vs: seq[IntArray[N]]): IntArray[N] =
  result = zeros(N)
  for v in vs:
    result += v

echo sum(@[ones(5), ones(5)])

# bug #6533
type Value[T: static[int]] = typedesc
proc foo(order: Value[1]): auto = 0
echo foo(Value[1])
