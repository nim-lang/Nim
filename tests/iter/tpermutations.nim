discard """
output: '''
@[@[1.0, 2.0], @[3.0, 4.0]]
perm: 10.0 det: -2.0
@[@[1.0, 2.0, 3.0, 4.0], @[4.0, 5.0, 6.0, 7.0], @[7.0, 8.0, 9.0, 10.0], @[10.0, 11.0, 12.0, 13.0]]
perm: 29556.0 det: 0.0
@[@[0.0, 1.0, 2.0, 3.0, 4.0], @[5.0, 6.0, 7.0, 8.0, 9.0], @[10.0, 11.0, 12.0, 13.0, 14.0], @[15.0, 16.0, 17.0, 18.0, 19.0], @[20.0, 21.0, 22.0, 23.0, 24.0]]
perm: 6778800.0 det: 0.0
'''
"""


import sequtils, sugar

iterator permutations*[T](ys: openArray[T]): tuple[perm: seq[T], sign: int] =
  var
    d = 1
    c = newSeq[int](ys.len)
    xs = newSeq[T](ys.len)
    sign = 1

  for i, y in ys: xs[i] = y
  yield (xs, sign)

  block outter:
    while true:
      while d > 1:
        dec d
        c[d] = 0
      while c[d] >= d:
        inc d
        if d >= ys.len: break outter

      let i = if (d and 1) == 1: c[d] else: 0
      swap xs[i], xs[d]
      sign *= -1
      yield (xs, sign)
      inc c[d]

proc det(a: seq[seq[float]]): float =
  let n = toSeq 0..a.high
  for sigma, sign in n.permutations:
    result += sign.float * n.map((i: int) => a[i][sigma[i]]).foldl(a * b)

proc perm(a: seq[seq[float]]): float =
  let n = toSeq 0..a.high
  for sigma, sign in n.permutations:
    result += n.map((i: int) => a[i][sigma[i]]).foldl(a * b)

for a in [
    @[ @[1.0, 2.0]
     , @[3.0, 4.0]
    ],
    @[ @[ 1.0,  2,  3,  4]
     , @[ 4.0,  5,  6,  7]
     , @[ 7.0,  8,  9, 10]
     , @[10.0, 11, 12, 13]
    ],
    @[ @[ 0.0,  1,  2,  3,  4]
     , @[ 5.0,  6,  7,  8,  9]
     , @[10.0, 11, 12, 13, 14]
     , @[15.0, 16, 17, 18, 19]
     , @[20.0, 21, 22, 23, 24]
    ] ]:
  echo a
  echo "perm: ", a.perm, " det: ", a.det

# bug #3499 last snippet fixed
# bug 705  last snippet fixed
