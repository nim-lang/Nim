discard """
  errmsg: "type mismatch: got <int>"
  line: 17
  nimout: '''type mismatch: got <int>
but expected one of:
proc inc[T: Ordinal](x: var T; y = 1)
  first type mismatch at position: 1
  required type for x: var T: Ordinal
  but expression 'i' is immutable, not 'var'

expression: inc i
'''
"""

for i in 0..10:
  echo i
  inc i
