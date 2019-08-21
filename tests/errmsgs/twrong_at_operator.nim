discard """
errormsg: "type mismatch: got <array[0..0, type int]>"
line: 22
nimout: '''
twrong_at_operator.nim(22, 30) Error: type mismatch: got <array[0..0, type int]>
but expected one of:
proc `@`[T](a: openArray[T]): seq[T]
  first type mismatch at position: 1
  required type for a: openarray[T]
  but expression '[int]' is of type: array[0..0, type int]
proc `@`[IDX, T](a: array[IDX, T]): seq[T]
  first type mismatch at position: 1
  required type for a: array[IDX, T]
  but expression '[int]' is of type: array[0..0, type int]

expression: @[int]
'''
disabled: "32bit"
"""

# bug #7331
var seqOfStrings: seq[int] = @[int]
