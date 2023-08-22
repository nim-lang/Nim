discard """
  errormsg: "expression cannot be isolated: a_to_b(a)"
  line: 22
"""

# bug #19013
import std/isolation

type Z = ref object
  i: int

type A = object
  z: Z

type B = object
  z: Z

func a_to_b(a: A): B =
  result = B(z: a.z)

let a = A(z: Z(i: 3))
let b = isolate(a_to_b(a))
