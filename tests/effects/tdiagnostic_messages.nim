discard """
  errormsg: "\'a\' has side effects as it calls \'callWithSideEffects\' here: tdiagnostic_messages.nim(12, 6)"
  file: "tdiagnostic_messages.nim"
  line: 19
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


# TODO:
#  - add hint for call location
#  - diagnostic renderer should be the same for `varpartitions.$` and `listSideEffects`
#  - update example in manual
#  - update existing tests
#  - finish this test

# Should the output be rendered like:
# <lineinfo> Error: `symbol` has side effects
#   <lineinfo> Hint: `symbol` accesses/mutates/calls `reason`
#     <lineinfo> Hint: `reason` declared here