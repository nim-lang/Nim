discard """
  output: '''
@[1, 2, 3, 4]
'''
"""

# issue #10999

proc varargsToSeq(vals: varargs[int32]): seq[int32] =
  result = newSeqOfCap[int32](vals.len)
  for v in vals:
    result.add v

echo varargsToSeq(1, 2, 3, 4)
