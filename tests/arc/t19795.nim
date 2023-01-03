discard """
  matrix: "--mm:arc"
"""

# bug #19795
# bug #21085

type Vector = seq[int]

var vect: Vector = newSeq[int](5)
doAssert vect == @[0, 0, 0, 0, 0]

# Needed to get the problem. Could also use "var".
let vectCopy = vect

# Then some procedure definition is needed to get the problem.
proc p(): int = 3

doAssert vect == @[0, 0, 0, 0, 0]