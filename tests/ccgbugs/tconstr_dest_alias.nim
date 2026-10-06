discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
arr local [2, 1]
arr var [3, 1]
arr ptr [7, 8]
arr ref [3, 1]
arr global [3, 1]
tup local (2, 1)
tup var (3, 1)
tup ptr (7, 8)
seq local @[2, 1]
seq var @[3, 1]
obj var (a: 3, arr: [5, 6])
obj ptr (a: 1, arr: [7, 8])
obj ptr field (a: 1, arr: [9, 8])
obj lent (a: 8, arr: [8, 7])
obj ref (a: 3, arr: [5, 6])
obj global (a: 3, arr: [5, 6])
obj call (a: 3, arr: [5, 6])
obj closure (a: 3, arr: [5, 6])
set small {2, 3}
set big {'2', 'z'}
set var {3, 5}
'''
"""

# Constructors are built in place unless their elements may read the
# destination. These are the cases where they may.

type
  O = object
    a: int
    arr: array[2, int]
  T = (int, int)
  A = array[2, int]
  RA = ref object
    a: A
  RO = ref object
    o: O

proc arrLocal() =
  var a: A = [1, 2]
  a = [a[1], a[0]]
  echo "arr local ", a

proc arrVar(w: var A, y: var A) =
  w = [3, y[0]]
  echo "arr var ", w

proc arrPtr() =
  var a: A = [7, 8]
  let q = addr a
  a = [q[0], q[1]]
  echo "arr ptr ", a

proc arrRef(w: var A, r: RA) =
  w = [3, r.a[0]]
  echo "arr ref ", w

var gA: A = [1, 2]
proc arrGlobal(w: var A) =
  w = [3, gA[0]]
  echo "arr global ", w

proc tupLocal() =
  var t: T = (1, 2)
  t = (t[1], t[0])
  echo "tup local ", t

proc tupVar(w: var T, y: var T) =
  w = (3, y[0])
  echo "tup var ", w

proc tupPtr() =
  var t: T = (7, 8)
  let q = addr t
  t = (q[0], q[1])
  echo "tup ptr ", t

proc seqLocal() =
  var s = @[1, 2]
  s = @[s[1], s[0]]
  echo "seq local ", s

proc seqVar(w: var seq[int], y: var seq[int]) =
  w = @[3, y[0]]
  echo "seq var ", w

proc objVar(w: var O, y: var O) =
  w = O(a: 3, arr: [y.a, y.arr[0]])
  echo "obj var ", w

proc objPtr() =
  var o = O(a: 7, arr: [8, 9])
  let q = addr o
  o = O(a: 1, arr: [q.a, q.arr[0]])
  echo "obj ptr ", o

proc objPtrField() =
  # `addr o.arr` does not mark `o` with `sfAddrTaken`
  var o = O(a: 7, arr: [8, 9])
  let q = addr o.arr
  o = O(a: 1, arr: [q[1], q[0]])
  echo "obj ptr field ", o

proc objLent() =
  var o = O(a: 7, arr: [8, 9])
  for x in o.arr:
    o = O(a: x, arr: [x, o.a])
    break
  echo "obj lent ", o

proc objRef(w: var O, r: RO) =
  w = O(a: 3, arr: [r.o.a, r.o.arr[0]])
  echo "obj ref ", w

var gO = O(a: 5, arr: [6, 7])
proc objGlobal(w: var O) =
  w = O(a: 3, arr: [gO.a, gO.arr[0]])
  echo "obj global ", w

proc readA(): int = gO.a
proc readArr(): int = gO.arr[0]
proc objCall(w: var O) =
  w = O(a: 3, arr: [readA(), readArr()])
  echo "obj call ", w

proc objClosure(w: var O, y: ptr O) =
  let cl = proc (): int = y.a
  let cl2 = proc (): int = y.arr[0]
  w = O(a: 3, arr: [cl(), cl2()])
  echo "obj closure ", w

proc setSmall() =
  var s: set[uint8] = {1, 2}
  s = {3'u8, uint8(card(s))}
  echo "set small ", s

proc setBig() =
  var s: set[char] = {'a', 'b'}
  s = {'z', char(ord('0') + card(s))}
  echo "set big ", s

proc setVar(w: var set[uint8], y: var set[uint8]) =
  w = {3'u8, (if 5'u8 in y: 5'u8 else: 0'u8)}
  echo "set var ", w

arrLocal()
var a: A = [1, 2]
arrVar(a, a)
arrPtr()
let ra = RA(a: [1, 2])
arrRef(ra.a, ra)
arrGlobal(gA)
tupLocal()
var t: T = (1, 2)
tupVar(t, t)
tupPtr()
seqLocal()
var s = @[1, 2]
seqVar(s, s)
var o = O(a: 5, arr: [6, 7])
objVar(o, o)
objPtr()
objPtrField()
objLent()
let ro = RO(o: O(a: 5, arr: [6, 7]))
objRef(ro.o, ro)
objGlobal(gO)
gO = O(a: 5, arr: [6, 7])
objCall(gO)
o = O(a: 5, arr: [6, 7])
objClosure(o, addr o)
setSmall()
setBig()
var st: set[uint8] = {5'u8}
setVar(st, st)
