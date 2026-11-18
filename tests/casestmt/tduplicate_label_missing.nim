discard """
  cmd: "nim check --hints:off $file"
  action: reject
  nimoutFull: true
  nimout: '''
tduplicate_label_missing.nim(15, 4) Error: duplicate case label
'''
"""

# a duplicate label does not also report "missing: {}"
type E = enum a, b
let x = a
case x
of a: discard
of a: discard
of b: discard
