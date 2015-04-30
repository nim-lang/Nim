discard """
file: "tsequtils.nim"
output: '''Zip: [{"Field0": 1, "Field1": 2}, {"Field0": 3, "Field1": 4}, {"Field0": 5, "Field1": 6}]
Filter Iterator: 3
Filter Iterator: 5
Filter Iterator: 7
Filter: [3, 5, 7]
FilterIt: [1, 3, 7]
Concat: [1, 3, 5, 7, 2, 4, 6]
Deduplicate: [1, 2, 3, 4, 5, 7]'''

"""

import sequtils, marshal

proc testFindWhere(item : int) : bool =
  if item != 1: return true

var seq1: seq[int] = @[]

seq1.add(1)
seq1.add(3)
seq1.add(5)
seq1.add(7)

var seq2: seq[int] = @[2, 4, 6]
var final = zip(seq1, seq2)

echo "Zip: ", $$(final)

#Test findWhere as a iterator

for itms in filter(seq1, testFindWhere):
  echo "Filter Iterator: ", $$(itms)


#Test findWhere as a proc

var fullseq: seq[int] = filter(seq1, testFindWhere)

echo "Filter: ", $$(fullseq)

#Test findIt as a template

var finditval: seq[int] = filterIt(seq1, it!=5)

echo "FilterIt: ", $$(finditval)

var concatseq = concat(seq1,seq2)
echo "Concat: ", $$(concatseq)

var seq3 = @[1,2,3,4,5,5,5,7]
var dedupseq = deduplicate(seq3)
echo "Deduplicate: ", $$(dedupseq)

