import sequtils

let
  short = @[1, 2, 3]
  long = @[6, 5, 4, 3, 2, 1]
  words = @["one", "two", "three"]
  zip1 = zip(short, long)
  zip2 = zip(short, words)
doAssert zip1 == @[(1, 6), (2, 5), (3, 4)]
doAssert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
doAssert zip1[2].b == 4
doAssert zip2[2].b == "three"
