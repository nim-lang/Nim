discard """
  file: "trecmacro.nim"
  line: 8
  errormsg: "recursive dependency: 'dump'"
"""

macro dump(n: stmt): stmt =
  dump(n)
  if kind(n) == nnkNone:
    nil
  else:
    hint($kind(n))
    for i in countUp(0, len(n)-1):
      nil
