discard """
  output: '''abc232'''
"""

var t, s: tuple[x: string, c: int]

proc ugh: seq[tuple[x: string, c: int]] = 
  result = @[("abc", 232)]

t = ugh()[0]
s = t
s = ugh()[0]

echo s[0], t[1]


