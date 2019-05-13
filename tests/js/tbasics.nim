discard """
  output: '''1'''
"""

# bug #10697
proc test2 =
  var val = uint16(0)
  var i = 0
  if i < 2:
    val += uint16(1)
  echo int(val)

test2()
