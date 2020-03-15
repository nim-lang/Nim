discard """
  errormsg: "illegal recursion in type"
"""

type
  MutualCyclicSeqA = distinct ref seq[MutualCyclicSeqB]
  MutualCyclicSeqB = distinct ref seq[MutualCyclicSeqC]
  MutualCyclicSeqC = distinct ref seq[MutualCyclicSeqA]
