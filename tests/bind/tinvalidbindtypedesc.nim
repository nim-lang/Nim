discard """
  errormsg: "type mismatch: got <typedesc[float], string>"
  line: 10
"""

proc foo(T: typedesc; some: T) =
  echo($some)

foo int, 4
foo float, "bad"
