discard """
  output: '''@[2]'''
"""

# bug #9684

var s2 = @[2, 2]

s2 = @[s2.len]

echo s2
