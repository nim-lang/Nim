# Test the closure implementation

proc map(n: var openarray[int], fn: proc (x: int): int {.closure}) =
  for i in 0..n.len-1: n[i] = fn(n[i])

proc foldr(n: openarray[int], fn: proc (x, y: int): int {.closure}): int =
  for i in 0..n.len-1:
    result = fn(result, n[i])

var
  myData: array[0..4, int] = [0, 1, 2, 3, 4]

proc testA() =
  var p = 0
  map(myData, proc (x: int): int =
                result = x + 1 shl (proc (y: int): int =
                  return y + p
                )(0)
                inc(p))

testA()
for x in items(myData):
  write(stout, x)
#OUT 2 4 6 8 10


