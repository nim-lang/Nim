discard """
  errormsg: "got <B, proc (b: B){.closure, gcsafe, locks: 0.}>"
  line: 20
"""

type
  A = ref object of RootObj
  B = ref object of A

  P = proc (a: A)

# bug #16325

proc doThings(a: A, p: P) =
  p(a)

var x = proc (b: B) {.closure.} =
  echo "B"

doThings(B(), x)
