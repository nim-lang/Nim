discard """
output: '''
@[(v: -1), (v: 2), (v: 3)]
@[(v: -1), (v: 2), (v: 3)]
[(v: -1), (v: 2), (v: 3)]
[(v: -1), (v: 2), (v: 3)]
((v: -1), (v: 2), (v: 3))
((v: -1), (v: 2), (v: 3))
@[(v: -1), (v: 2), (v: 3)]
@[(v: -1), (v: 2), (v: 3)]
@[(v: -1), (v: 2), (v: 3)]
'''
"""

type mytype* = object
  v:int

proc f*(x:ptr mytype) = x.v = -1

func g(x:int):mytype = mytype(v:x)


import xseq9578
block:
  var x = @[1.g,2.g,3.g]
  testSeq(x)
  echo x
block:
  var x = @[1.g,2.g,3.g]
  var y = addr x
  testSeq2(y)
  echo x


import xarray9578
block:
  var x = [1.g,2.g,3.g]
  testArray(x)
  echo x
block:
  var x = [1.g,2.g,3.g]
  var y = addr x
  testArray2(y)
  echo x


import xtuple9578
block:
  var x = (1.g,2.g,3.g)
  testTuple(x)
  echo x
block:
  var x = (1.g,2.g,3.g)
  var y = addr x
  testTuple2(y)
  echo x


import xoa9578
block:
  var x = @[1.g,2.g,3.g]
  testOpenArray(x)
  echo x


import xua9578
block:
  var x = @[1.g,2.g,3.g]
  var y = cast[ptr UncheckedArray[mytype]](addr x[0])
  testUncheckedArray(y[])
  echo x
block:
  var x = @[1.g,2.g,3.g]
  var y = cast[ptr UncheckedArray[mytype]](addr x[0])
  testUncheckedArray2(y)
  echo x
