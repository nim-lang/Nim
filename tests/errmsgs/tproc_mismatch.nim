discard """
  action: reject
  cmd: '''nim check --hints:off $options $file'''
  nimoutFull: true
  nimout: '''
tproc_mismatch.nim(35, 52) Error: type mismatch: got <proc (a: int, c: float){.cdecl, noSideEffect, gcsafe, locks: 0.}> but expected 'proc (a: int, c: float){.closure, noSideEffect.}'
  Calling convention mismatch: got '{.cdecl.}', but expected '{.closure.}'.
tproc_mismatch.nim(39, 6) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}>
but expected one of:
proc bar(a: proc ())
  first type mismatch at position: 1
  required type for a: proc (){.closure.}
  but expression 'fn1' is of type: proc (){.inline, noSideEffect, gcsafe, locks: 0.}
  Calling convention mismatch: got '{.inline.}', but expected '{.closure.}'.

expression: bar(fn1)
tproc_mismatch.nim(43, 8) Error: type mismatch: got <proc (){.inline, noSideEffect, gcsafe, locks: 0.}> but expected 'proc (){.closure.}'
  Calling convention mismatch: got '{.inline.}', but expected '{.closure.}'.
tproc_mismatch.nim(48, 8) Error: type mismatch: got <proc (){.locks: 0.}> but expected 'proc (){.closure, noSideEffect.}'
  Pragma mismatch: got '{..}', but expected '{.noSideEffect.}'.
tproc_mismatch.nim(52, 8) Error: type mismatch: got <proc (a: int){.noSideEffect, gcsafe, locks: 0.}> but expected 'proc (a: float){.closure.}'
tproc_mismatch.nim(61, 9) Error: type mismatch: got <proc (a: int){.locks: 0.}> but expected 'proc (a: int){.closure, gcsafe.}'
  Pragma mismatch: got '{..}', but expected '{.gcsafe.}'.
tproc_mismatch.nim(69, 9) Error: type mismatch: got <proc (a: int): int{.nimcall.}> but expected 'proc (a: int): int{.cdecl.}'
  Calling convention mismatch: got '{.nimcall.}', but expected '{.cdecl.}'.
tproc_mismatch.nim(70, 9) Error: type mismatch: got <proc (a: int): int{.cdecl.}> but expected 'proc (a: int): int{.nimcall.}'
  Calling convention mismatch: got '{.cdecl.}', but expected '{.nimcall.}'.
tproc_mismatch.nim(74, 9) Error: type mismatch: got <proc (a: int){.closure, locks: 3.}> but expected 'proc (a: int){.closure, locks: 1.}'
  Pragma mismatch: got '{.locks: 3.}', but expected '{.locks: 1.}'.
lock levels differ
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
block: # Lock levels differ
  var fn1: proc(a: int){.locks: 3.}
  var fn2: proc(a: int){.locks: 1.}
  fn2 = fn1
