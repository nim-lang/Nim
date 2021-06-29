discard """
  action: reject
  cmd: '''nim check --hints:off $file'''
  nimoutFull: true
  nimout: '''
tproc_mismatch.nim(26, 52) Error: type mismatch: got <proc (a: int, c: float){.cdecl, noSideEffect, gcsafe, locks: 0.}> but expected 'proc (a: int, c: float){.closure, noSideEffect.}'
  Calling convention: mismatch got '{.cdecl.}', but expected '{.closure.}'.
tproc_mismatch.nim(30, 6) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}>
but expected one of: 
proc bar(a: proc ())
  first type mismatch at position: 1
  required type for a: proc (){.closure.}
  but expression 'fn1' is of type: proc (){.inline, noSideEffect, gcsafe, locks: 0.}
  Calling convention: mismatch got '{.inline.}', but expected '{.closure.}'.

expression: bar(fn1)
tproc_mismatch.nim(34, 8) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}> but expected 'proc (){.closure.}'
  Calling convention: mismatch got '{.inline.}', but expected '{.closure.}'.
tproc_mismatch.nim(39, 8) Error: type mismatch: got <proc (){.locks: 0.}> but expected 'proc (){.closure, noSideEffect.}'
  Calling convention: mismatch got '{.nimcall.}', but expected '{.closure.}'.
  Pragma mismatch: got '{..}', but expected '{.noSideEffect.}'.
'''
"""
block: # CallConv/Pragma mismatch
  func a(a: int, c: float) {.cdecl.} = discard
  var b: proc(a: int, c: float) {.noSideEffect.} = a
block: # Parameter CallConv mismatch
  proc fn1() {.inline.} = discard
  proc bar(a: proc()) = discard
  bar(fn1)
block: # CallConv mismatch
  proc fn1() {.inline.} = discard
  var fn: proc()
  fn = fn1
block: # Pragma mismatch
  var a = ""
  proc fn1() = a.add "b"
  var fn: proc() {.noSideEffect.}
  fn = fn1
