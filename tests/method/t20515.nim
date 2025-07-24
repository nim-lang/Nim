discard """
  errormsg: "Base method 'zzz' requires explicit '{.gcsafe.}' to be GC-safe"
  line: 10
"""

type
  A = ref object of RootObj
  B = ref object of A

method zzz(a: A) {.base.} =
  discard

var s: seq[int]
method zzz(a: B) =
  echo s

proc xxx(someObj: A) {.gcsafe.} =
  someObj.zzz()

xxx(B())
