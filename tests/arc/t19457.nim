discard """
  matrix: "--gc:refc; --gc:arc"
"""

# bug #19457
proc gcd(x, y: seq[int]): seq[int] =
    var
      a = x
      b = y
    while b[0] > 0:
      let c = @[a[0] mod b[0]]
      a = b
      b = c
    return a

doAssert gcd(@[1], @[2]) == @[1]