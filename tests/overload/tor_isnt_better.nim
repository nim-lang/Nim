type
  D[T] = object
  E[T] = object

block: # PR #22261
  proc d(x: D):bool= false
  proc d(x: int | D[SomeInteger]):bool= true
  doAssert d(D[5]()) == false

block: # bug #8568
#[
  Since PR #22261 and amendment has been made. Since D is a subset of D | E but
  not the other way around `checkGeneric` should favor proc g(a: D) instead
  of asserting ambiguity
]#
  proc g(a: D|E): string = "foo D|E"
  proc g(a: D): string = "foo D"
  doAssert g(D[int]()) == "foo D"
