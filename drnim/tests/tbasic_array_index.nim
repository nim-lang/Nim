discard """
  nimout: '''tbasic_array_index.nim(21, 17) Warning: cannot prove: 0 <= len(a) - 4; counter example: a.len -> 3 [IndexCheck]
tbasic_array_index.nim(21, 17) Warning: cannot prove: len(a) - 4 <= 9223372036854775807; counter example: a.len -> 9223372036854775812 [IndexCheck]'''
  cmd: "drnim $file"
  action: "compile"
"""

{.push staticBoundChecks: on.}

proc takeNat(n: Natural) =
  discard

proc p(a: openArray[int]) =
  if a.len > 0:
    echo a[0]

  for i in 0..a.len-8:
    #{.invariant: i < a.len.}
    echo a[i]

  takeNat(a.len - 4)

{.pop.}

p([1, 2, 3])
