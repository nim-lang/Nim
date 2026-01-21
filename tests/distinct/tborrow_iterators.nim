import std/tables

type
  NumberList = object
    items: seq[int]

iterator values(list: NumberList): int =
  for item in list.items:
    yield item

type DistinctNumberList = distinct NumberList

iterator values(list: DistinctNumberList): int {.borrow.}

static:
  doAssert compiles((block:
    let base = NumberList(items: @[1, 2, 3])
    let distinctBase = DistinctNumberList(base)
    var total = 0
    for value in values(distinctBase):
      total += value
    var totalDot = 0
    for value in distinctBase.values:
      totalDot += value
    doAssert total == 6
    doAssert totalDot == 6
  ))

type
  Box[T] = object
    items: seq[T]

iterator items[T](box: Box[T]): T =
  for item in box.items:
    yield item

type DistinctBox[T] = distinct Box[T]

iterator items(box: DistinctBox[int]): int {.borrow.}

static:
  doAssert compiles((block:
    let genericBase = Box[int](items: @[4, 5])
    let distinctGeneric = DistinctBox[int](genericBase)
    var genericTotal = 0
    for item in distinctGeneric.items:
      genericTotal += item
    doAssert genericTotal == 9
  ))

type
  DistinctSeq = distinct seq[int]
  DistinctSeqNoBorrow = distinct seq[int]

iterator items(s: DistinctSeq): lent int {.borrow.}

static:
  doAssert compiles((block:
    let distinctSeqValue = DistinctSeq(@[10, 20])
    for value in distinctSeqValue:
      discard value
  ))

let distinctSeqValue = DistinctSeq(@[10, 20])
var distinctSeqBorrowedTotal = 0
# Ensure borrowed items iterator works for distinct seq at runtime.
for value in distinctSeqValue:
  distinctSeqBorrowedTotal += value
doAssert distinctSeqBorrowedTotal == 30

let distinctSeqBase = seq[int](distinctSeqValue)
var distinctSeqTotal = 0
for value in distinctSeqBase:
  distinctSeqTotal += value
doAssert distinctSeqTotal == 30

static:
  doAssert not compiles((block:
    let missingBorrow = DistinctSeqNoBorrow(@[10, 20])
    for value in missingBorrow:
      discard value
  ))

type
  DistinctArray = distinct array[3, int]
  DistinctArrayNoBorrow = distinct array[3, int]

iterator items(a: DistinctArray): int {.borrow.}

static:
  doAssert compiles((block:
    let distinctArrayValue = DistinctArray([1, 2, 3])
    for value in distinctArrayValue:
      discard value
  ))

let distinctArrayValue = DistinctArray([1, 2, 3])
var distinctArrayBorrowedTotal = 0
# Ensure borrowed items iterator works for distinct arrays at runtime.
for value in distinctArrayValue:
  distinctArrayBorrowedTotal += value
doAssert distinctArrayBorrowedTotal == 6

let distinctArrayBase = array[3, int](distinctArrayValue)
var distinctArrayTotal = 0
for value in distinctArrayBase:
  distinctArrayTotal += value
doAssert distinctArrayTotal == 6

static:
  doAssert not compiles((block:
    let missingBorrowArray = DistinctArrayNoBorrow([1, 2, 3])
    for value in missingBorrowArray:
      discard value
  ))

type
  BaseTable = Table[string, int]
  DistinctTable = distinct BaseTable
  DistinctTableNoBorrow = distinct BaseTable

iterator pairs(t: DistinctTable): (string, int) {.borrow.}

static:
  doAssert compiles((block:
    var baseTable: BaseTable
    baseTable["a"] = 4
    let distinctTableValue = DistinctTable(baseTable)
    for _, value in distinctTableValue:
      discard value
  ))

var baseTable: BaseTable
baseTable["a"] = 4
baseTable["b"] = 5
let distinctTableValue = DistinctTable(baseTable)
var distinctTableBorrowedTotal = 0
# Ensure borrowed pairs iterator works for distinct table wrappers at runtime.
for _, value in distinctTableValue:
  distinctTableBorrowedTotal += value
doAssert distinctTableBorrowedTotal == 9

let distinctTableBase = BaseTable(distinctTableValue)
var tableTotal = 0
for _, value in distinctTableBase:
  tableTotal += value
doAssert tableTotal == 9

static:
  doAssert not compiles((block:
    var missingBorrowTable: BaseTable
    missingBorrowTable["a"] = 1
    let distinctMissing = DistinctTableNoBorrow(missingBorrowTable)
    for _, value in distinctMissing:
      discard value
  ))
