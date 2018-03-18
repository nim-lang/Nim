discard """
errormsg: "type mismatch: got <array[0..0, type int]>"
line: 15
nimout: '''
twrong_at_operator.nim(15, 30) Error: type mismatch: got <array[0..0, type int]>
but expected one of:
proc `@`[T](a: openArray[T]): seq[T]
proc `@`[IDX, T](a: array[IDX, T]): seq[T]

expression: @[int]
'''
"""

# bug #7331
var seqOfStrings: seq[int] = @[int]
