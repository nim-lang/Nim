import sequtils

let
  dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
  dup2 = @["a", "a", "c", "d", "d"]
  unique1 = deduplicate(dup1)
  unique2 = deduplicate(dup2)
doAssert unique1 == @[1, 3, 4, 2, 8]
doAssert unique2 == @["a", "c", "d"]
