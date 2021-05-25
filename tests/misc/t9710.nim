discard """
  matrix: "--debugger:native"
"""
# bug #9710
for i in 1 || 200:
  discard i
