import unittest
import typetraits as tt

type
  TA = tuple[a: int, b: string]
  TB = tuple
    a,b: int
    c,d: string
  TC = object
    a: int
    b,c: string
  TD = object of TObject
    a,b,c: int
    d,e: string

let
  arTA = tt.arity(TA)
  arTB = tt.arity(TB)
  arTC = tt.arity(TC)
  arTD = tt.arity(TD)

suite "typetraits arity suite":
  test "arity of tuples should equal number of fields":
    check(2 == arTA)
    check(4 == arTB)
  test "arity of objects should equal number of fields":
    check(3 == arTC)
    check(5 == arTD)

