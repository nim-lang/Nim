discard """
cmd: "nim check $file"
errormsg: "type mismatch"
nimout: '''
Error: type mismatch: got <int literal(1), uint8>
but expected one of:
proc fun3[T1, T2](a: T1; b: T2): int
  enableIf condition failed: 'T1.sizeof == T2.sizeof'
'''
"""




## line 15

block:
  proc fun3[T1, T2](a: T1, b: T2): int {.enableif: T1.sizeof == T2.sizeof.} = 41
  fun3(1, 1'u8)
