discard """
  output: '''@[1, 42, 3]
@[1, 42, 3]
'''
"""
proc xxx() =
  var x: seq[int] = @[1, 2, 3]
  var y: seq[int]

  system.shallowCopy(y, x)

  y[1] = 42

  echo y
  echo x

xxx()
