discard """
  matrix: "--mm:refc; --mm:orc; --mm:arc"
  output: "ok"
"""

# bug #26712: in-place construction must not expose partial writes of the
# destination or let a constructor value read the half written destination.

type
  H = object
    a, b: int
  S = object
    s: string
    t: seq[int]
proc m(): int = raise new IOError
proc ms(): string = raise new IOError

proc main() =
  # local in try
  var o = H(b: 1)
  try:
    o = H(a: 5, b: m())
  except IOError: discard
  doAssert o == H(b: 1), $o
  var a = [1, 2]
  try:
    a = [7, m()]
  except IOError: discard
  doAssert a == [1, 2], $a
  var t = (1, 2)
  try:
    t = (7, m())
  except IOError: discard
  doAssert t == (1, 2), $t
  t = (t[1], t[0])
  doAssert t == (2, 1)
  # managed fields
  var s = S(s: "x", t: @[1])
  try:
    s = S(t: @[9], s: ms())
  except IOError: discard
  doAssert s.s == "x" and s.t == @[1], $s
  var q = @[1, 2]
  try:
    q = @[7, m()]
  except IOError: discard
  doAssert q == @[1, 2], $q
  var sa = ["a", "b"]
  sa = [sa[1], sa[0]]
  doAssert sa == ["b", "a"]
  try:
    sa = ["z", ms()]
  except IOError: discard
  doAssert sa == ["b", "a"], $sa

var gs = S(s: "x", t: @[1])
proc rd(): string = gs.s & "!"
gs = S(t: @[2], s: rd())
doAssert gs.s == "x!", $gs
var gt = (1, 2)
proc rt(): int = gt[0]
gt = (5, rt())
doAssert gt == (5, 1), $gt
var ga = [1, 2]
proc ra(): int = ga[0]
ga = [5, ra()]
doAssert ga == [5, 1], $ga
main()
static:
  main()

block: # the original report
  type H = object
    a, b: int
  var o = H(b: 1)
  proc g(): int = o.b
  o = H(b: g())
  doAssert o == H(b: 1)
  o = H()
  try:
    o = H(a: 1, b: m())
  except IOError:
    discard
  doAssert o == H()
  var a = [1, 2]
  a = [a[1], a[0]]
  doAssert a == [2, 1]
  a = [0, 0]
  try:
    a = [1, m()]
  except IOError:
    discard
  doAssert a == [0, 0]

echo "ok"
