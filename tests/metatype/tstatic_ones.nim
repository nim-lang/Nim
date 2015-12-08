discard """
  file: "tstatic_ones.nim"
  output: "@[2, 2, 2, 2, 2]"
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
