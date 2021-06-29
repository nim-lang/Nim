discard """
  action: reject
  matrix: "--hints:off"
  nimoutFull: true
  nimout: '''
tproc_mismatch4.nim(14, 6) Error: type mismatch: got <proc (){.locks: 0.}> but expected 'proc (){.closure, noSideEffect.}'
Calling convention: mismatch got '{.nimcall.}', but expected '{.closure.}'.
Pragma mismatch: got '{..}', but expected '{.noSideEffect.}'.
'''
"""
var a = ""
proc fn1() = a.add "b"
var fn: proc(){.noSideEffect.}
fn = fn1
