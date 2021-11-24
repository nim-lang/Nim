var s: seq[int]
s.add block:
  let i = 1
  i
s.add try:
  2
except:
  3
doAssert s == @[1, 2]
