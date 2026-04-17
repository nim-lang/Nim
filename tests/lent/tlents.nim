discard """
  targets: "c cpp"
"""

type A = object
  field: int

proc x(a: A): lent int =
  result = case true
    of true:
      a.field
    of false:
      a.field

proc y(a: A): lent int =
  result = if true:
      a.field
    else:
      a.field

block:
  var a = A(field: 1)
  doAssert x(a) == 1
  doAssert y(a) == 1


import std/tables

block:
  type
    R = proc(): lent O {.nimcall.}
    F = object
      schema: R
    O = object
      fields: Table[string, F]

  func f(o: O, key: string): R =
    if key in o.fields: o.fields[key].schema
    else: nil

block:
  type
    R = proc(): lent O
    O = object
      r: R

  func f(o: O): int = 42
