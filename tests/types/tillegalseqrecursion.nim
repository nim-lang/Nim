discard """
  errormsg: "illegal recursion in type 'CyclicSeq'"
"""
# issue #13715
type
  CyclicSeq = seq[ref CyclicSeq]
