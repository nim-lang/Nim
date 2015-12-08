discard """
  file: "taddhigh.nim"
  output: '''@[5, 5, 5]'''
"""

# bug #1832

var s = @[5]

# Works fine:
let x = s[s.high]
s.add x

# Causes the 0 to appear:
s.add s[s.high]

echo s # @[5, 5, 0]
