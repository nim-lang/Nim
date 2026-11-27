discard """
  matrix: "--mm:refc; --mm:orc; --mm:orc -d:release"
  ccodecheck: "\\i !@('tyObject_Payload' [a-zA-Z0-9_]* \\s+ ('T' [0-9]+ '_' / 'colontmpD_' [0-9_]*) ';')"
  output: '''
0 
0 x 2
1 0 @[1]
0 3 2
'''
"""

# bug #26707: `dest = Constr(f: default(T))` must not evaluate the huge
# `default(T)` into a stack temporary before `=destroy(dest)`.

type
  T = (array[1 shl 24, byte], string)
  D = object
    e: T

var r: D
r = D(e: default(T))
echo r.e[0][0], " ", r.e[1]

type
  Payload = object
    arr: array[1 shl 24, byte]
    s: string
  Holder = object
    p: Payload
    n: int
    s: seq[int]
  Outer = object
    h: Holder
    tag: string

proc reset(w: var Holder) =
  # the read of `w.n` still happens before `w` is destroyed
  w = Holder(p: default(Payload), n: w.n + 1, s: @[1])

proc nested(o: var Outer) =
  o = Outer(h: Holder(p: default(Payload), n: 3, s: @[]), tag: "x")

block:
  var o = Outer(tag: "x")
  o.h.p.s = "abc"
  o.h.n = 1
  reset(o.h)
  echo o.h.p.arr[0], " ", o.tag, " ", o.h.n
  echo o.h.s.len, " ", o.h.p.s.len, " ", o.h.s
  nested(o)
  echo o.h.p.arr[0], " ", o.h.n, " ", o.h.s.len + o.tag.len + 1
