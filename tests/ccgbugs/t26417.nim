discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('tyObject_Big' [a-zA-Z0-9_]* \\s+ 'T' [0-9]+ '_;')"
  output: '''
1
2
@[1, 2, 3]
4
@[1, 2]
5
caught
sink 8
x!
7 2 2 4 5 @[1]
9
'''
"""

# bug #26417: no stack copy of a huge object for `w = construct(typeof(w), d)`

type Big = object
  s: seq[int]
  d: int
  data: array[16 * 1024 * 1024, byte]

template construct(T: type, x: int): untyped =
  T(d: x)

proc reset(w: var Big, d: int) =
  w = construct(typeof(w), d)

proc reset2(w: var Big, d: int) =
  w = Big(d: d)

let a = new Big
a[].reset(1)
echo a.d
a[].reset2(2)
echo a.d

# the constructor reads the destination:
proc grow(w: var Big) =
  w = Big(s: w.s & @[w.s.len + 1], d: w.d + 1)

a[] = Big(s: @[1, 2], d: 3)
a[].grow()
echo a.s
echo a.d

# the destination and a by-reference parameter alias:
proc take(w: var Big; b: Big) =
  w = Big(s: b.s, d: b.d + 1)

a[] = Big(s: @[1, 2], d: 4)
take(a[], a[])
echo a.s
echo a.d

# an exception in a field value:
proc boom(): seq[int] = raise newException(ValueError, "boom")

proc tryReset(w: var Big) =
  w = Big(s: boom(), d: 99)

a[] = Big(s: @[7], d: 6)
try:
  tryReset(a[])
except ValueError:
  echo "caught"

# user-defined `=sink` is still called:
type Hooked = object
  x: int

proc `=sink`(dest: var Hooked; src: Hooked) =
  echo "sink ", src.x
  dest.x = src.x

proc setH(h: var Hooked; v: int) =
  h = Hooked(x: v)

var h = Hooked(x: 1)
setH(h, 8)

# case objects keep their field checks:
type
  Kind = enum kA, kB
  Variant = object
    data: array[16 * 1024 * 1024, byte]
    case k: Kind
    of kA: a: seq[int]
    of kB: b: string

proc setV(v: var Variant; s: string) =
  v = Variant(k: kB, b: s & "!")

let v = new Variant
setV(v[], "x")
echo v.b

# arbitrary paths as the destination:
type
  Holder = object
    x: int
    inner: Big
    arr: array[2, Big]
  RH = ref Holder

proc p1(h: var Holder; d: int) = h.inner = Big(d: d)
proc p2(h: var Holder; i, d: int) = h.arr[i] = Big(d: d)
proc p3(h: RH; i, d: int) = h.arr[i] = Big(d: d)
proc p4(s: var seq[Big]; i, d: int) = s[i] = Big(d: d)
proc p5(s: seq[RH]; i, d: int) = s[i].inner = Big(d: d)
proc p6(h: var Holder; d: int) = h.inner = typeof(h.inner)(d: d)
proc p7(h: var Holder) = h.inner = Big(s: h.inner.s & @[1], d: h.x)
proc p8(h: var Holder; i: int) = h.arr[i] = Big(d: h.arr[1-i].d)
proc p9(h: RH; d: int) = h[].arr[0] = Big(d: d)

block:
  var h = RH(x: 7)
  p1(h[], 1); p2(h[], 1, 2); p3(h, 0, 3)
  var s = newSeq[Big](2); p4(s, 1, 4)
  var rs = @[RH()]; p5(rs, 0, 5)
  p6(h[], 6); p7(h[]); p8(h[], 0)
  echo h.inner.d, " ", h.arr[0].d, " ", h.arr[1].d, " ", s[1].d, " ", rs[0].inner.d, " ", h.inner.s
  p9(h, 9)
  echo h.arr[0].d
