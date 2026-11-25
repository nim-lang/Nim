discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
0 0 0
(a: 2, b: 1)
abcx abcxx
@[2, 1] @[1, 2]
@[1, 2] @[1, 2]
'''
"""

# bug #26491: no temporary per branch for value producing control flow

var x: array[9999, int]

proc f(i: int): int = (if i == 0: x else: x)[i]
proc g(i: int): int = (case i
  of 0: x
  else: x)[i]
proc h(i: int): int =
  let t = if i == 0: x else: x
  t[i]

echo f(0), " ", g(1), " ", h(2)

type O = object
  a, b: int

proc aliased(i: int) =
  var t = O(a: 1, b: 2)
  t = if i == 0: O(a: t.b, b: t.a) else: t
  echo t
aliased(0)

proc aliasedStr(i: int) =
  var t = "abc"
  t = if i == 0: t & "x" else: "y"
  var u = if i == 0: t & "x" else: "y"
  echo t, " ", u
aliasedStr(0)

proc aliasedSeq(i: int) =
  var t = @[1, 2]
  t = if i == 0: @[t[1], t[0]] else: t
  var u = if i == 0: @[t[1], t[0]] else: t
  echo t, " ", u
aliasedSeq(0)
aliasedSeq(1)
