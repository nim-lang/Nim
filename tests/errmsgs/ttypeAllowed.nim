discard """
cmd: "nim check $file"
nimout: '''
ttypeAllowed.nim(13, 5) Error: invalid type: 'iterator (a: int, b: int, step: Positive): int{.inline, noSideEffect, gcsafe, locks: 0.}' for let
ttypeAllowed.nim(17, 7) Error: invalid type for const: iterator (a: int, b: int, step: Positive): int{.inline, noSideEffect, gcsafe, locks: 0.}
ttypeAllowed.nim(21, 5) Error: invalid type: 'iterator (a: int, b: int, step: Positive): int{.inline, noSideEffect, gcsafe, locks: 0.}' for var
ttypeAllowed.nim(26, 10) Error: invalid type: 'iterator (a: int, b: int, step: Positive): int{.inline, noSideEffect, gcsafe, locks: 0.}' for result
ttypeAllowed.nim(31, 20) Error: invalid type: 'iterator (){.inline.}' in this context: 'iterator (a: openArray[int], b: openArray[int]): iterator (){.inline.}{.inline, gcsafe, locks: 0.}' for proc
'''
"""

let f1 = case true
  of true:  countup[int]
  of false: countdown[int]

const f2 = case true
  of true:  countup[int]
  of false: countdown[int]

var f3 = case true
  of true:  countup[int]
  of false: countdown[int]

proc foobar(): auto =
  result = case true
    of true:  countup[int]
    of false: countdown[int]

# issue #5701

iterator zip[T1,T2](a: openarray[T1], b: openarray[T2]): iterator() {.inline.} =
  let len = min(a.len, b.len)
  for i in 0..<len:
    echo (a[i], b[i])

for i in zip([1,2,3],[1,2,3]):
  discard
