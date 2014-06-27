import combinatorics, sets, math, sequtils

proc checkUnique[T](s: seq[T]): seq[T] =
  doAssert len(toSet(s)) == len(s)
  return s

template count(s: expr): int =
  len(checkUnique(toSeq(s)))

proc testPermutations() = 
  for i in 0..6:
    doAssert count(permutations(toSeq(1..i))) == fac(i)

proc testChoices() =
  for i in 1..5:
    for j in 0..i:
      doAssert count(choices(toSeq(1..i), j)) == binom(i, j)

proc testCombinations() =
  for i in 1..5:
    var p = 1
    for j in 0..5:
      doAssert count(combinations(toSeq(1..i), j)) == p
      p *= i

testPermutations()
testChoices()
testCombinations()
