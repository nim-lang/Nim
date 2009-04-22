# Test the closure implementation

proc map(n: var openarray[int], fn: proc (x: int): int {.closure}) =
  for i in 0..n.len-1:
    n[i] = fn(n[i])

proc foldr(n: openarray[int], fn: proc (x, y: int): int {.closure}): int =
  result = 0
  for i in 0..n.len-1:
    result = fn(result, n[i])

var
  myData: array[0..9, int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

proc testA() =
  var p = 0
  map(myData, lambda (x: int): int =
                result = x + 1 shl (lambda (y: int): int =
                  return y + 1
                )(0)
                inc(p), 88)

testA()
for x in items(myData):
  echo x
