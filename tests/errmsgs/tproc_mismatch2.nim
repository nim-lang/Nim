discard """
  action: reject
  matrix: "--hints:off"
  nimoutFull: true
  nimout: '''
tproc_mismatch2.nim(19, 4) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}>
but expected one of: 
proc bar(a: proc ())
  first type mismatch at position: 1
  required type for a: proc (){.closure.}
  but expression 'fn1' is of type: proc (){.inline, noSideEffect, gcsafe, locks: 0.}
  Calling convention: mismatch got '{.inline.}', but expected '{.closure.}'.

expression: bar(fn1)
'''
"""
proc fn1() {.inline.} = discard
proc bar(a: proc()) = discard
bar(fn1)
