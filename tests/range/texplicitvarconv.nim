discard """
  errormsg: "type mismatch: got <int>"
  nimout: "but expression 'int(a)' is immutable, not 'var'"
  line: 16
"""
# related to issue #24032 and #26775

proc `++`(n: var int) =
    n += 1

type
    r = range[ 0..15 ]

var a: r = 14

++int(a) # a range conversion keeps no l-value: the increment could leave 0..15
