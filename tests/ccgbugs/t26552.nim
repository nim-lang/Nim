discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
kB
abc
kA
3
'''
"""

# bug #26552: resetting a case object must not zero GC-free arrays
# element by element.

type
  Big = object
    a: array[64, array[8, int]]
  K = enum kA, kB
  Obj = object
    s: string
    case kind: K
    of kA:
      x: Big
      refs: array[3, ref int]
    of kB: y: Big
  R = ref object
    o: Obj

proc put(r: R, v: Big) {.noinline.} =
  r.o = Obj(kind: kB, y: v, s: "abc")

var r = R(o: Obj(kind: kA))
r.o.refs[1] = new(int)
r.o.refs[1][] = 3
var b: Big
b.a[3][4] = 7
put(r, b)
echo r.o.kind
echo r.o.s
doAssert r.o.y.a[3][4] == 7
r.o = Obj(kind: kA)
r.o.refs[2] = new(int)
r.o.refs[2][] = 3
echo r.o.kind
GC_fullCollect()
echo r.o.refs[2][]
