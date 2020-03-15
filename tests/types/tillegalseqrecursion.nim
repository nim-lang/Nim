discard """
  errormsg: "illegal recursion in type 'CyclicSeq'"
"""

type
  CyclicSeq = seq[ref CyclicSeq]
