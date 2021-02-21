discard """
  errormsg: "type mismatch: got <byte, int literal(0)>"
  nimout: '''but expected one of:
proc fun0[T1: int | float | object | array | seq](a1: T1; a2: int)
  first type mismatch at position: 1
  required type for a1: T1: int or float or object or array or seq
  but expression 'byte(1)' is of type: byte

expression: fun0(byte(1), 0)
'''
"""

proc fun0[T1:int|float|object|array|seq](a1:T1, a2:int)=discard

fun0(byte(1), 0)
