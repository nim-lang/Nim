
discard """
  line: 9
  errormsg: "address of 'result' may not escape its stack frame"
"""
# bug #5113

proc makeSeqVar(size: Natural): var seq[int] =
  newSeq(result, size)
