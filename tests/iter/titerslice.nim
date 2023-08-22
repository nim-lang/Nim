discard """
  output: '''2
3
4'''
"""

var t1 = @["1", "2", "3", "4"]
for t in t1[1..3]:
  echo t
