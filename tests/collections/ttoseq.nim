import sequtils

# toSeq test
let
  numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
    if x mod 2 == 1:
      result = true)
doAssert odd_numbers == @[1, 3, 5, 7, 9]
