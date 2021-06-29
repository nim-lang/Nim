discard """
  action: reject
  matrix: "--declaredLocs --hints:off"
  nimoutFull: true
  nimout: '''tproc_mismatch.nim(12, 49) Error: type mismatch:
 got <proc (a: int, c: float){.cdecl, noSideEffect, gcsafe, locks: 0.}> [proc]
 but expected 'proc (a: int, c: float){.closure, noSideEffect.}' [proc]
Calling convention: mismatch got '{.cdecl.}', but expected '{.closure.}'.
'''
"""
func a(a: int, c: float){.cdecl.} = discard
var b: proc(a: int, c: float){.noSideEffect.} = a
