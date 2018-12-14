
discard """
  errormsg: "address of 'result' may not escape its stack frame"
  line: 9
"""
# bug #5113

proc makeSeqVar(size: Natural): var seq[int] =
  newSeq(result, size)
