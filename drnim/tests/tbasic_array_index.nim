discard """
  nimout: '''tbasic_array_index.nim(26, 17) Warning: cannot prove: 0 <= len(a) - 4; counter example: a.len -> 0 [IndexCheck]
tbasic_array_index.nim(32, 5) Warning: cannot prove: 4.0 <= 1.0 [IndexCheck]
tbasic_array_index.nim(38, 36) Warning: cannot prove: a <= 10'u32; counter example: a -> #x000000000000000b
'''
  cmd: "drnim $file"
  action: "compile"
"""

{.push staticBoundChecks: defined(nimDrNim).}

proc takeNat(n: Natural) =
  discard

proc p(a, b: openArray[int]) =
  if a.len > 0:
    echo a[0]

  for i in 0..a.len-8:
    #{.invariant: i < a.len.}
    echo a[i]

  for i in 0..min(a.len, b.len)-1:
    echo a[i], " ", b[i]

  takeNat(a.len - 4)

proc r(x: range[0.0..1.0]) = echo x

proc sum() =
  r 1.0
  r 4.0

proc ru(x: range[1u32..10u32]) = echo x

proc xu(a: uint) =
  if a >= 4u:
    let chunk = range[1u32..10u32](a)
    ru chunk

proc parse(s: string) =
  var i = 0

  while i < s.len and s[i] != 'a':
    inc i

parse("abc")

{.pop.}

p([1, 2, 3], [4, 5])
