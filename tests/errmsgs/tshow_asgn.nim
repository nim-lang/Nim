discard """
  errormsg: "type mismatch: got <int> but expected 'cshort = int16'"
  line: 12
  column: 27
  file: "tshow_asgn.nim"
"""

# bug #5430

proc random*[T](x: Slice[T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  result = int(x.b - x.a) + x.a

let slice = 10.cshort..15.cshort
discard slice.random
