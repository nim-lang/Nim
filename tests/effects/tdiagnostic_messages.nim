discard """
  nimoutFull: true
  action: "reject"
  cmd: "nim r --hint:Conf:off $file"
  nimout: '''tdiagnostic_messages.nim(35, 6) Error: 'a' can have side effects
> tdiagnostic_messages.nim(36, 30) Hint: 'a' calls `.sideEffect` 'callWithSideEffects'
>> tdiagnostic_messages.nim(28, 6) Hint: 'callWithSideEffects' called by `.noSideEffect` 'a'
>>> tdiagnostic_messages.nim(30, 34) Hint: 'callWithSideEffects' calls `.sideEffect` 'indirectCallViaVarParam'
>>>> tdiagnostic_messages.nim(24, 6) Hint: 'indirectCallViaVarParam' called by `.noSideEffect` 'callWithSideEffects'
>>>>> tdiagnostic_messages.nim(25, 7) Hint: 'indirectCallViaVarParam' calls routine via hidden pointer indirection
>>> tdiagnostic_messages.nim(31, 33) Hint: 'callWithSideEffects' calls `.sideEffect` 'indirectCallViaPointer'
>>>> tdiagnostic_messages.nim(26, 6) Hint: 'indirectCallViaPointer' called by `.noSideEffect` 'callWithSideEffects'
>>>>> tdiagnostic_messages.nim(27, 32) Hint: 'indirectCallViaPointer' calls routine via pointer indirection
>>> tdiagnostic_messages.nim(32, 10) Hint: 'callWithSideEffects' calls `.sideEffect` 'myEcho'
>>>> tdiagnostic_messages.nim(23, 6) Hint: 'myEcho' called by `.noSideEffect` 'callWithSideEffects'
>>> tdiagnostic_messages.nim(33, 3) Hint: 'callWithSideEffects' accesses global state 'globalVar'
>>>> tdiagnostic_messages.nim(22, 5) Hint: 'globalVar' accessed by `.noSideEffect` 'callWithSideEffects'

'''
"""

var globalVar = 0
proc myEcho(a: string) {.sideEffect.} = discard
proc indirectCallViaVarParam(call: var proc(): int {.nimcall.}): int =
  call()
proc indirectCallViaPointer(call: pointer): int =
  cast[ptr proc(): int](call)[]()
proc callWithSideEffects(): int =
  var p = proc (): int {.nimcall.} = 0
  discard indirectCallViaVarParam(p)
  discard indirectCallViaPointer(addr p)
  myEcho ""
  globalVar

func a: int =
  discard callWithSideEffects()
