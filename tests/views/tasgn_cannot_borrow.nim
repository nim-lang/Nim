discard """
  errormsg: "'giveSeqItem(s)' borrows from location 's' which is mutated via 'modifySeq(s)'"
  line: 19
"""

{.experimental: "views".}

# bug #18683
proc modifySeq(s: var seq[int]): int =
  s.add 42
  42

proc giveSeqItem(s: var seq[int]): var int =
  s[0]

proc main =
  var s = @[1, 2, 3]

  giveSeqItem(s) = modifySeq(s)
main()
