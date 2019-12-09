discard """
  errormsg: "recursive dependency: 'dump'"
  file: "trecmacro.nim"
  line: 8
"""

macro dump(n: untyped): untyped =
  dump(n)
  if kind(n) == nnkNone:
    nil
  else:
    hint($kind(n))
    for i in countUp(0, len(n)-1):
      nil
