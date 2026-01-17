import std/tables

##[
This testcase checks that nested bracket operators can be borrowed on distinct
seq/table/array types.
]##

type
  NestedArray = distinct array[2, float]
  NestedTable = distinct Table[int, NestedArray]
  NestedSeq = distinct seq[NestedTable]

proc `[]`*(s: NestedSeq, i: int): NestedTable {.borrow.}
proc `[]`*(s: var NestedSeq, i: int): var NestedTable {.borrow.}
proc `[]`*(t: NestedTable, key: int): NestedArray {.borrow.}
proc `[]`*(t: var NestedTable, key: int): var NestedArray {.borrow.}
proc `[]`*(a: NestedArray, i: int): float {.borrow.}
proc `[]`*(a: var NestedArray, i: int): var float {.borrow.}

block:
  var baseTable: Table[int, NestedArray]
  baseTable[123] = NestedArray([0.0, 0.0])
  var table = NestedTable(baseTable)

  var testObj = NestedSeq(@[table])

  testObj[0][123][1] = 1.23
  let element = testObj[0][123][1]
  doAssert element == 1.23
  let firstElement = testObj[0][123][0]
  doAssert firstElement == 0.0

  testObj[0][123][0] = 2.34
  doAssert testObj[0][123][0] == 2.34
