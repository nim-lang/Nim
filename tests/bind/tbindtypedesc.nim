discard """
  line: 11
  file: "tbindtypedesc.nim"
  errormsg: "type mismatch: got (typedesc[float], string)"
"""

proc foo(T: typedesc; some: T) =
  echo($some)

foo int, 4
foo float, "bad"

