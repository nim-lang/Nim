discard """
  line: 10
  errormsg: "type mismatch: got <type float, string>"
"""

proc foo(T: typedesc; some: T) =
  echo($some)

foo int, 4
foo float, "bad"

