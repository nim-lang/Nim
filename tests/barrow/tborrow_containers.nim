import std/[sets, tables]

##[
This testcase checks that common container operations can be borrowed for
distinct seqs, tables, sets, arrays, and tuples.
]##

type
  DistinctSeqInt = distinct seq[int]

proc len*(s: DistinctSeqInt): int {.borrow.}

block:
  var s = DistinctSeqInt(@[1, 2, 3])
  doAssert s.len == 3

type
  DistinctTableStrInt = distinct Table[string, int]

proc hasKey*(t: DistinctTableStrInt, key: string): bool {.borrow.}

block:
  var base = initTable[string, int]()
  base["a"] = 4
  let t = DistinctTableStrInt(base)
  doAssert t.hasKey("a")


type
  DistinctHashSetInt = distinct HashSet[int]

proc contains*(s: DistinctHashSetInt, v: int): bool {.borrow.}
proc incl*(s: var DistinctHashSetInt, v: int) {.borrow.}

block:
  var hs = DistinctHashSetInt(initHashSet[int]())
  hs.incl 5
  doAssert hs.contains(5)
