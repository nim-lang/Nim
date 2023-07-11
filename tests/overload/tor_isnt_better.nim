# PR #22261
#[
  An amendment to this test has been made. Since D is a subset of D | E but
  not the other way around `checkGeneric` should favor proc g(a: D) instead
  of asserting ambiguity
]#

# bug #8568

type
  D[T] = object
  E[T] = object

proc g(a: D|E): string = "foo D|E"
proc g(a: D): string = "foo D"

proc test() =
  doAssert g(D[int]()) == "foo D"

test()
