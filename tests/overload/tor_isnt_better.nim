discard """
  errormsg: "ambiguous call;"
  line: 16
"""

# bug #8568

type
  D[T] = object
  E[T] = object

proc g(a: D|E): string = "foo D|E"
proc g(a: D): string = "foo D"

proc test() =
  let x = g D[int]()

test()
