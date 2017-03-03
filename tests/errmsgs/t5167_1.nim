discard """
errormsg: "'bar' doesn't have a concrete type, due to unspecified generic parameters."
line: 16
"""

proc foo[T]() =
  var y1 = foo[string]
  var y2 = foo[T]

proc bar[T]() =
  let x = 0

let good1 = foo[int]
let good2 = bar[int]

let err = bar

