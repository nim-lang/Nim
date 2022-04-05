import stdtest/testutils

block: # assertAll
  assertAll:
    1+1 == 2
    var a = 3
    a == 3

  doAssertRaises(AssertionDefect):
    assertAll:
      1+1 == 2
      var a = 3
      a == 4

block: # greedyOrderedSubsetLines
  assertAll:
    greedyOrderedSubsetLines("a1\na3", "a0\na1\na2\na3\na4")
    not greedyOrderedSubsetLines("a3\na1", "a0\na1\na2\na3\na4") # out of order
    not greedyOrderedSubsetLines("a1\na5", "a0\na1\na2\na3\na4") # a5 not in lhs

    not greedyOrderedSubsetLines("a1\na5", "a0\na1\na2\na3\na4\nprefix:a5")
    not greedyOrderedSubsetLines("a1\na5", "a0\na1\na2\na3\na4\na5:suffix")
    not greedyOrderedSubsetLines("a5", "a0\na1\na2\na3\na4\nprefix:a5")
    not greedyOrderedSubsetLines("a5", "a0\na1\na2\na3\na4\na5:suffix")

block: # greedyOrderedSubsetLines with allowPrefixMatch = true
  template fn(a, b): bool =
    greedyOrderedSubsetLines(a, b, allowPrefixMatch = true)
  assertAll:
    fn("a1\na3", "a0\na1\na2\na3_suffix\na4")
    not fn("a1\na3", "a0\na1\na2\nprefix_a3\na4")
    # these are same as above, could be refactored
    not fn("a3\na1", "a0\na1\na2\na3\na4") # out of order
    not fn("a1\na5", "a0\na1\na2\na3\na4") # a5 not in lhs

    not fn("a1\na5", "a0\na1\na2\na3\na4\nprefix:a5")
    fn("a1\na5", "a0\na1\na2\na3\na4\na5:suffix")
    not fn("a5", "a0\na1\na2\na3\na4\nprefix:a5")
    fn("a5", "a0\na1\na2\na3\na4\na5:suffix")
