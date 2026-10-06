discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('tyObject_F' [a-zA-Z0-9_]* \\s+ 'T' [0-9]+ '_;')"
  output: '''1
2
3
5'''
"""

# bug #26274: a field value that is a plain scalar variable cannot alias the
# destination. Construct directly in the destination, without a large stack
# temporary.
type F = object
  b: array[24576, byte]
  d: int

proc p(w: var F, x: int) = w = F(d: x)

proc r(w: var F) =
  let y = w.d + 1
  w = F(d: y)

var s: F
s.b[0] = 42
p(s, 1)
doAssert s.b[0] == 0
echo s.d
r(s)
echo s.d

var g = 3
proc viaGlobal(w: var F) = w = F(d: g)
viaGlobal(s)
echo s.d

# the self-aliasing case still has to read the old value
type O = object
  a: int
  arr: array[2, int]

var o = O(a: 5)
o = O(a: 1, arr: [o.a, 2])
echo o.arr[0]
