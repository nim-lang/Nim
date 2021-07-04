discard """
  errormsg: "\'a\' can have side effects"
  nimout: '''  tdiagnostic_messages.nim(32, 30) Hint: 'a' calls 'callWithSideEffects' which has side effects
    tdiagnostic_messages.nim(24, 6) Hint: 'callWithSideEffects' called by a `noSideEffect` routine, but has side effects
      tdiagnostic_messages.nim(26, 34) Hint: 'callWithSideEffects' calls 'indirectCallViaVarParam' which has side effects
        tdiagnostic_messages.nim(20, 6) Hint: 'indirectCallViaVarParam' called by a `noSideEffect` routine, but has side effects
          tdiagnostic_messages.nim(21, 7) Hint: 'indirectCallViaVarParam' calls a routine with side effects via hidden pointer indirection
      tdiagnostic_messages.nim(27, 33) Hint: 'callWithSideEffects' calls 'indirectCallViaPointer' which has side effects
        tdiagnostic_messages.nim(22, 6) Hint: 'indirectCallViaPointer' called by a `noSideEffect` routine, but has side effects
          tdiagnostic_messages.nim(23, 32) Hint: 'indirectCallViaPointer' calls a routine with side effects via pointer indirection
      tdiagnostic_messages.nim(28, 8) Hint: 'callWithSideEffects' calls 'echo' which has side effects
        ../../lib/system.nim(2004, 6) Hint: 'echo' called by a `noSideEffect` routine, but has side effects
      tdiagnostic_messages.nim(29, 3) Hint: 'callWithSideEffects' accesses global state 'globalVar'
        tdiagnostic_messages.nim(19, 5) Hint: 'globalVar' accessed by a `noSideEffect` routine'''
  file: "tdiagnostic_messages.nim"
  line: 31
"""

var globalVar = 0
proc indirectCallViaVarParam(call: var proc(): int {.nimcall.}): int =
  call()
proc indirectCallViaPointer(call: pointer): int =
  cast[ptr proc(): int](call)[]()
proc callWithSideEffects(): int =
  var p = proc (): int {.nimcall.} = 0
  discard indirectCallViaVarParam(p)
  discard indirectCallViaPointer(addr p)
  echo ""
  globalVar

func a: int =
  discard callWithSideEffects()
