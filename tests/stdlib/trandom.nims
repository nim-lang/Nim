import std/[random, sets]

block: # bug #17898
  const size = 1000
  var
    rands: array[size, Rand]
    randSet: HashSet[Rand]
  for i in 0..<size:
    rands[i] = initRand()
    randSet.incl rands[i]

  doAssert randSet.len == size

echo "Nim script test done!"
