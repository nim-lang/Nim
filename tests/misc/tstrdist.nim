# compute the edit distance between two strings

proc editDistance(a, b: string): int =
  var
    c: seq[int]
    n = a.len
    m = b.len
  newSeq(c, (n+1)*(m+1))
  for i in 0..n:
    c[i*n] = i # [i,0]
  for j in 0..m:
    c[j] = j # [0,j]

  for i in 1..n:
    for j in 1..m:
      var x = c[(i-1)*n + j]+1
      var y = c[i*n + j-1]+1
      var z: int
      if a[i-1] == b[j-1]:
        z = c[(i-1)*n + j-1]
      else:
        z = c[(i-1)*n + j-1]+1
      c[(i-1)*n + (j-1)] = min(x,min(y,z))
  return c[n*m]

doAssert editDistance("abc", "abd") == 3
