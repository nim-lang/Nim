discard """
  matrix: "--mm:refc; --mm:orc; --mm:orc -d:release"
  ccodecheck: "\\i !@('tyObject_Big' [a-zA-Z0-9_]* \\s+ ('T' [0-9]+ '_' / 'colontmpD_' [0-9_]*) ';')"
  output: '''
true 0
false true
true 0
'''
"""

# bug #26711: switching the branch of a huge case object via
# `r = J(k: true)` must not materialize the implicit `zeroDefault` of the
# large branch field in a stack temporary.

type
  Big = object
    a: array[1 shl 24, byte]
  J = object
    case k: bool
    of false: s: ref int
    of true: b: Big

var r: J
r = J(k: true)
echo r.k, " ", r.b.a[high(r.b.a)]
r = J(k: false, s: new int)
echo r.k, " ", r.s != nil

let h = new J
h[] = J(k: true)
echo h.k, " ", h.b.a[0]
