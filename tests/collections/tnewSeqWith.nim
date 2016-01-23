import sequtils

# newSeqWith tests
var seq2D = newSeqWith(4, newSeq[bool](2))
seq2D[0][0] = true
seq2D[1][0] = true
seq2D[0][1] = true
doAssert seq2D == @[@[true, true], @[true, false], @[false, false], @[false, false]]
