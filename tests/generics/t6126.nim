discard """
  output: '''
f got 0.0 1.0 2.0
f got 0.0 1.0 2.0
f got 0 1 2
f got 0 1 2
'''
"""

# bug #6126: generic type declared inside a generic proc
proc f[T](x: openArray[T]) =
  var s = "f got"
  for a in x: s &= " " & $a
  echo s

proc gt[T] =
  type
    M[N: static[int]] = object
      d: array[N, T]
  var A {.noinit.}: M[3]
  for i in 0..<A.N: A.d[i] = T(i)
  f(A.d)
  var B: array[3, T]
  for i in 0..<B.len: B[i] = T(i)
  f(B)

gt[float]()
gt[int]()
