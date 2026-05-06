discard """
  errormsg: "cannot infer the type of the array"
"""

proc doNothingWith[T](x: T): T = x

let x = doNothingWith((@[], 1))