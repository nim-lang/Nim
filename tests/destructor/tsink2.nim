discard """
  matrix: "--mm:refc; --mm:arc"
"""

block: # bug #12340
  func consume(x: sink seq[int]) =
    x[0] += 5

  let x = @[1, 2, 3, 4]
  consume x
  doAssert x == @[1, 2, 3, 4]
