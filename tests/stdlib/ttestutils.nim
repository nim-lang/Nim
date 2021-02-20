import stdtest/testutils

block: # greedyOrderedSubsetLines
  doAssert greedyOrderedSubsetLines("a1\na3", "a0\na1\na2\na3\na4")
  doAssert not greedyOrderedSubsetLines("a3\na1", "a0\na1\na2\na3\na4") # out of order
  doAssert not greedyOrderedSubsetLines("a1\na5", "a0\na1\na2\na3\na4") # a5 not in lhs
