discard """
errormsg: "type mismatch: got <array[0..0, type int]>"
line: 29
nimout: '''
Hint: used config file '/home/travis/build/nim-lang/Nim/config/nim.cfg' [Conf]
Hint: used config file '/home/travis/build/nim-lang/Nim/config/config.nims' [Conf]
Hint: used config file '/home/travis/build/nim-lang/Nim/tests/config.nims' [Conf]
Hint: system [Processing]
Hint: widestrs [Processing]
Hint: io [Processing]
Hint: twrong_at_operator [Processing]
twrong_at_operator.nim(29, 30) Error: type mismatch: got <array[0..0, type int]>
but expected one of:
proc `@`[T](a: openArray[T]): seq[T]
  first type mismatch at position: 1
  required type for a: openarray[T]
  but expression '[int]' is of type: array[0..0, type int]
proc `@`[IDX, T](a: sink array[IDX, T]): seq[T]
  first type mismatch at position: 1
  required type for a: sink array[IDX, T]
  but expression '[int]' is of type: array[0..0, type int]

expression: @[int]
'''
disabled: "32bit"
"""

# bug #7331
var seqOfStrings: seq[int] = @[int]
