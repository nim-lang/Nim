discard """
  matrix:"-d:nimTest_t16576"
"""

# bug #16576
doAssert defined(nimTest_t16576)
doAssert not defined(nimMegatest)
