discard """
  errormsg: "ambiguous call"
"""

#[
The rational here is that although A is an implicit generic and 
`T` has more "generic depth" they are equivallent expressions and
therefore are ambigous
]#

type
  A[T] = object
  C = object

proc test[H;T: A[H]](param: T): bool = false
proc test(param: A): bool = true
doAssert test(A[C]()) == true  # previously would pass
