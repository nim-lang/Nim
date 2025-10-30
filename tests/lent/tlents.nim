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

