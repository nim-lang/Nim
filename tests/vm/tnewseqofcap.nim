discard """
  output: '''@["aaa", "bbb", "ccc"]'''
"""


const
  foo = @["aaa", "bbb", "ccc"]

proc myTuple: tuple[n: int, bar: seq[string]] =
  result.n = 42
  result.bar = newSeqOfCap[string](foo.len)
  for f in foo:
    result.bar.add(f)

# It works if you change the below `const` to `let`
const
  (n, bar) = myTuple()

echo bar