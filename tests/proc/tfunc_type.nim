
discard """
  errmsg: "type mismatch: got <proc (a: int): int{.gcsafe, locks: 0.}> but expected 'proc (a: int): int{.closure, noSideEffect.}"
"""

type
  MyObject = object
    fn: func(a: int): int

proc myproc(a: int): int =
  echo "bla"
  result = a

var x = MyObject(fn: myproc)