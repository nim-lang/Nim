discard """
output: '''true'''
"""

# https://github.com/nim-lang/Nim/issues/1147
type TTest = object
  vals: seq[int]

proc add*(self: var TTest, val: int) =
  self.vals.add(val)

type CAddable = concept x
  x[].add(int)

echo((ref TTest) is CAddable)

