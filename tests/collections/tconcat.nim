import sequtils

let
  s1 = @[1, 2, 3]
  s2 = @[4, 5]
  s3 = @[6, 7]
  total = concat(s1, s2, s3)
doAssert total == @[1, 2, 3, 4, 5, 6, 7]
