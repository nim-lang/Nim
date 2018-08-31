discard """
  output: '''c'''
"""

var a: array['a'..'c', string] = ["a", "b", "c"]

echo a[^1]
