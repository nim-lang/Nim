discard """
  matrix: "--mm:arc --multimethods:off; --mm:refc --multimethods:off"
  output: '''base
base
base
base
base
base
'''
"""

# bug #10912

type
  X = ref object of RootObj

type
  A* = ref object of RootObj
  B* = ref object of A
  C* = ref object of A
  D* = ref object of A
  E* = ref object of A
  F* = ref object of A

method resolve(self: var X, stmt: A) {.base.} = echo "base"

proc resolveSeq*(self: var X, statements: seq[A]) =
  for statement in statements:
    resolve(self, statement)

method resolve(self: var X, stmt: B) =
  echo "B"

method resolve(self: var X, stmt: D) =
  echo "D"

method resolve(self: var X, stmt: E) =
  echo "E"

method resolve(self: var X, stmt: C) =
  echo "C"

method resolve(self: var X, stmt: F) =
  echo "F"

var x = X()
var a = @[A(), B(), C(), D(), E(), F()]
resolveSeq(x, a)
