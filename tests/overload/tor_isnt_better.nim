
# issue #22142
#[
  An amendment to this test has been made. Since D is a subset of D | E but
  not the other way around the `checkGeneric` should favor proc g(a: D) instead.
  This test no longer expects ambiguity because there shouldn't have been.
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
