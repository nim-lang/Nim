discard """
  action: reject
  cmd: '''nim check --hints:off $options $file'''
  nimoutFull: true
  nimout: '''tunexpandedmacro.nim(24, 45) Error: expression 'await doThing()' has no type (or is ambiguous)
tunexpandedmacro.nim(25, 17) Error: expression 'waitFor doThing()' has no type (or is ambiguous)
tunexpandedmacro.nim(32, 16) Error: type mismatch: got <int64> but expected 'float'
tunexpandedmacro.nim(36, 25) Error: type mismatch: got <int64> but expected 'float32'
tunexpandedmacro.nim(39, 7) Error: type mismatch: got <int64>
but expected one of:
proc immVar(v: var int64)
  first type mismatch at position: 1
  required type for v: var int64
  but expression 'emitInt()' is immutable, not 'var'

expression: immVar(100'i64)
'''
"""


import std/[asyncdispatch, macros]

proc doThing: Future[void] {.async.} = discard
proc doOtherThing {.async.} = discard await doThing()
discard waitfor doThing()

template doThing(a: int): untyped =
  case a:
  of 100: 300i64
  of 200: 400i64
  else: a
var a: float = doThing(300)

macro emitInt(): untyped = newLit(100i64)

var b: float32 = emitInt()

proc immVar(v: var int64) = discard
immVar(emitInt())
