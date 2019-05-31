discard """
  errmsg: "type mismatch: got <int>"
  line: 15
  nimout: '''type mismatch: got <int>
but expected one of:
proc inc[T: Ordinal | uint | uint64](x: var T; y = 1)
  for a 'var' type a variable needs to be passed, but 'i' is immutable

expression: inc i
'''
"""

for i in 0..10:
  echo i
  inc i
