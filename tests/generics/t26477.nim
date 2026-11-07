discard """
  errormsg: "cannot instantiate O"
  line: 10
"""

# issue #26477

type O[T] = object

proc f(x: O[]) = discard
