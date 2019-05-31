discard """
errormsg: "type mismatch: got <array[0..0, type int]>"
line: 16
nimout: '''
twrong_at_operator.nim(16, 30) Error: type mismatch: got <array[0..0, type int]>
but expected one of:
proc `@`[T](a: openArray[T]): seq[T]
proc `@`[IDX, T](a: array[IDX, T]): seq[T]

expression: @[int]
'''
disabled: "32bit"
"""

# bug #7331
var seqOfStrings: seq[int] = @[int]
