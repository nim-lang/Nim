discard """
errormsg: "type mismatch: got <array[0..0, typedesc[int]]>"
nimout: '''
twrong_at_operator.nim(21, 30) Error: type mismatch: got <array[0..0, typedesc[int]]>
but expected one of:
proc `@`[IDX, T](a: sink array[IDX, T]): seq[T]
  first type mismatch at position: 1
  required type for a: sink array[IDX, T]
  but expression '[int]' is of type: array[0..0, typedesc[int]]
proc `@`[T](a: openArray[T]): seq[T]
  first type mismatch at position: 1
  required type for a: openArray[T]
  but expression '[int]' is of type: array[0..0, typedesc[int]]

expression: @[int]
'''
disabled: "32bit"
"""

# bug #7331
var seqOfStrings: seq[int] = @[int]
