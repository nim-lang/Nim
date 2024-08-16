discard """
  action: reject
  cmd: '''nim check --hints:off $options $file'''
  nimoutFull: true
  nimout: '''
tproc_mismatch.nim(38, 52) Error: type mismatch: got <proc (a: int, c: float){.cdecl, noSideEffect, gcsafe.}> but expected 'proc (a: int, c: float){.closure, noSideEffect.}'
  Calling convention mismatch: got '{.cdecl.}', but expected '{.closure.}'.
tproc_mismatch.nim(42, 6) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe.}>
but expected one of:
proc bar(a: proc ())
  first type mismatch at position: 1
  required type for a: proc (){.closure.}
  but expression 'fn1' is of type: proc (){.inline, noSideEffect, gcsafe.}
  Calling convention mismatch: got '{.inline.}', but expected '{.closure.}'.

expression: bar(fn1)
tproc_mismatch.nim(46, 8) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe.}> but expected 'proc (){.closure.}'
  Calling convention mismatch: got '{.inline.}', but expected '{.closure.}'.
tproc_mismatch.nim(51, 8) Error: type mismatch: got <proc ()> but expected 'proc (){.closure, noSideEffect.}'
  Calling convention mismatch: got '{.nimcall.}', but expected '{.closure.}'.
  Pragma mismatch: got '{..}', but expected '{.noSideEffect.}'.
tproc_mismatch.nim(55, 8) Error: type mismatch: got <proc (a: int){.noSideEffect, gcsafe.}> but expected 'proc (a: float){.closure.}'
  Calling convention mismatch: got '{.nimcall.}', but expected '{.closure.}'.
tproc_mismatch.nim(64, 9) Error: type mismatch: got <proc (a: int)> but expected 'proc (a: int){.closure, gcsafe.}'
  Calling convention mismatch: got '{.nimcall.}', but expected '{.closure.}'.
  Pragma mismatch: got '{..}', but expected '{.gcsafe.}'.
tproc_mismatch.nim(72, 9) Error: type mismatch: got <proc (a: int): int{.nimcall.}> but expected 'proc (a: int): int{.cdecl.}'
  Calling convention mismatch: got '{.nimcall.}', but expected '{.cdecl.}'.
tproc_mismatch.nim(73, 9) Error: type mismatch: got <proc (a: int): int{.cdecl.}> but expected 'proc (a: int): int{.nimcall.}'
  Calling convention mismatch: got '{.cdecl.}', but expected '{.nimcall.}'.
'''
"""



block: # CallConv mismatch
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
block: # Fail match not do to Pragma or CallConv
  proc fn1(a: int) = discard
  var fn: proc(a: float)
  fn = fn1
block: # Infered noSideEffect assign
  type Foo = ref object
    x0: int
  var g0 = Foo(x0: 1)
  proc fn1(a: int) = g0.x0 = a
  var fn2: proc(a: int)
  var fn3: proc(a: int) {.gcsafe.}
  fn2 = fn1
  fn3 = fn1
block: # Indrection through pragmas
  {.pragma: inl1, inline.}
  {.pragma: inl2, inline.}
  {.pragma: p1, nimcall.}
  {.pragma: p2, cdecl.}
  var fn1: proc(a: int): int {.inl1, p1.}
  var fn2: proc(a: int): int {.inl2, p2.}
  fn2 = fn1
  fn1 = fn2

