discard """
ccodeCheck: "\\i @'NIM_ALIGN(128) NI mylocal1' .*"
matrix: "--mm:refc -d:useGcAssert -d:useSysAssert; --mm:orc"
targets: "c cpp"
output: "align ok"
"""

# This is for Azure. The keyword ``alignof`` only exists in ``c++11``
# and newer. On Azure gcc does not default to c++11 yet.

import globalalignas

var toplevel1 {.align: 32.} : int32
var toplevel2 {.align: 32.} : int32
var toplevel3 {.align: 32.} : int32

proc foobar() =
  var myvar1 {.global, align(64).}: int = 123
  var myvar2 {.global, align(64).}: int = 123
  var myvar3 {.global, align(64).}: int = 123

  doAssert (cast[uint](addr(myglobal1)) and 127) == 0
  doAssert (cast[uint](addr(myglobal2)) and 127) == 0
  doAssert (cast[uint](addr(myglobal3)) and 127) == 0

  doAssert (cast[uint](addr(myvar1)) and 63) == 0
  doAssert (cast[uint](addr(myvar2)) and 63) == 0
  doAssert (cast[uint](addr(myvar3)) and 63) == 0

  doAssert (cast[uint](addr(toplevel1)) and 31) == 0
  doAssert (cast[uint](addr(toplevel2)) and 31) == 0
  doAssert (cast[uint](addr(toplevel3)) and 31) == 0

  # test multiple align expressions
  var mylocal1 {.align(128), align(32).}: int = 123
  var mylocal2 {.align(128), align(32).}: int = 123
  var mylocal3 {.align(32), align(128).}: int = 123

  doAssert (cast[uint](addr(mylocal1)) and 127) == 0
  doAssert (cast[uint](addr(mylocal2)) and 127) == 0
  doAssert (cast[uint](addr(mylocal3)) and 127) == 0

  echo "align ok"

foobar()

# bug #13122

type Bug[T] = object
  bug{.align:64.}: T
  sideffect{.align:64.}: int

var bug: Bug[int]
doAssert sizeof(bug) == 128, "Oops my size is " & $sizeof(bug) # 16


block: # bug #22419
  type
    ValidatorPubKey = object
      blob: array[96, byte]

  proc f(): auto =
    return iterator() =
      var pad: int8 = 0
      var y {.align: 16.}: ValidatorPubKey
      let value = cast[uint64](addr y)
      doAssert value mod 16 == 0

  f()()


type Xxx = object
  v {.align: 128.}: byte

type Yyy = object
  v: byte
  v2: Xxx

for i in 0..<3:
  let x = new Yyy
  # echo "addr v2.v:", cast[uint](addr x.v2.v)
  doAssert cast[uint](addr x.v2.v) mod 128 == 0

let m = new Yyy
m.v2.v = 42
doAssert m.v2.v == 42
m.v = 7
doAssert m.v == 7


type
  MyType16 = object
    a {.align(16).}: int


var x: array[10, ref MyType16]
for q in 0..500:
  for i in 0..<x.len:
    new x[i]
    x[i].a = q
    doAssert(cast[int](x[i]) mod alignof(MyType16) == 0)

type
  MyType32  = object
    a{.align(32).}: int

var y: array[10, ref MyType32]
for q in 0..500:
  for i in 0..<y.len:
    new y[i]
    y[i].a = q
    doAssert(cast[int](y[i]) mod alignof(MyType32) == 0)

# Additional tests: allocate custom aligned objects using `new`
type
  MyType64 = object
    a{.align(64).}: int

var z: array[10, ref MyType64]
for q in 0..500:
  for i in 0..<z.len:
    new z[i]
    z[i].a = q
    doAssert(cast[int](z[i]) mod alignof(MyType64) == 0)

type
  MyType128 = object
    a{.align(128).}: int

var w: array[10, ref MyType128]
for q in 0..500:
  for i in 0..<w.len:
    new w[i]
    w[i].a = q
    doAssert(cast[int](w[i]) mod alignof(MyType128) == 0)

# Nested aligned-object tests
type
  Inner128 = object
    v {.align(128).}: byte

  OuterWithInner = object
    prefix: int
    inner: Inner128

var outerArr: array[8, ref OuterWithInner]
for q in 0..200:
  for i in 0..<outerArr.len:
    new outerArr[i]
    # write to inner to ensure it's allocated
    outerArr[i].inner.v = cast[byte](q and 0xFF)
    doAssert(cast[uint](addr outerArr[i].inner) mod uint(alignof(Inner128)) == 0)

# Nested two-level alignment
type
  DeepInner = object
    b {.align(128).}: int

  Mid = object
    di: DeepInner

  Top = object
    m: Mid

var topArr: array[4, ref Top]
for q in 0..100:
  for i in 0..<topArr.len:
    new topArr[i]
    topArr[i].m.di.b = q
    doAssert(cast[uint](addr topArr[i].m.di) mod uint(alignof(DeepInner)) == 0)

