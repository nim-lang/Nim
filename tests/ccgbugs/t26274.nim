discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('tyObject_F' [a-zA-Z0-9_]* \\s+ 'T' [0-9]+ '_;')"
  output: '''
1
2
(a: 3, b: 5)
'''
"""

# bug #26274: `dest = Constr(...)` where the constructor does not mention
# `dest` is built directly in `dest`, without a (potentially huge) temporary.
type
  F = object
    b: array[24576, byte]
    d: int
  O = object
    a, b: int

proc p(w: var F, x: int) = w = F(d: x)

proc local(x: int): int =
  var loc: F
  loc = F(d: x + 1)
  result = loc.d

var s: F
s.b[0] = 42
p(s, 1)
doAssert s.b[0] == 0
echo s.d
echo local(1)

proc aliased(w: var O, y: var O) =
  # `w` is not mentioned, but `y` may alias it
  w = O(a: 3, b: y.a)

var o = O(a: 5, b: 6)
aliased(o, o)
echo o
