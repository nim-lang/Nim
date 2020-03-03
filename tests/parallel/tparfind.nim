discard """
  output: "500"
"""

import threadpool, sequtils

{.experimental: "parallel".}

proc linearFind(a: openArray[int]; x, offset: int): int =
  for i, y in a:
    if y == x: return i+offset
  result = -1

proc parFind(a: seq[int]; x: int): int =
  var results: array[4, int]
  parallel:
    if a.len >= 4:
      let chunk = a.len div 4
      results[0] = spawn linearFind(a[0 ..< chunk], x, 0)
      results[1] = spawn linearFind(a[chunk ..< chunk*2], x, chunk)
      results[2] = spawn linearFind(a[chunk*2 ..< chunk*3], x, chunk*2)
      results[3] = spawn linearFind(a[chunk*3 ..< a.len], x, chunk*3)
  result = max(results)


let data = toSeq(0..1000)
echo parFind(data, 500)

