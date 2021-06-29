discard """
  action: reject
  matrix: "--hints:off"
  nimoutFull: true
  nimout: '''
tproc_mismatch3.nim(12, 6) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}> but expected 'proc (){.closure.}'
Calling convention: mismatch got '{.inline.}', but expected '{.closure.}'.
'''
"""
proc fn1() {.inline.} = discard
var fn: proc()
fn = fn1
