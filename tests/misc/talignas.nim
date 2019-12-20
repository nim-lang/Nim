discard """
cmd: "nim $target $options -d:useSysAssert $file"
ccodeCheck: "\\i @'NIM_ALIGN(128) NI mylocal1' .*"
target: "c cpp"
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
  var mylocal1 {.align(0), align(128), align(32).}: int = 123
  var mylocal2 {.align(128), align(0), align(32).}: int = 123
  var mylocal3 {.align(0), align(32), align(128).}: int = 123

  doAssert (cast[uint](addr(mylocal1)) and 127) == 0
  doAssert (cast[uint](addr(mylocal2)) and 127) == 0
  doAssert (cast[uint](addr(mylocal3)) and 127) == 0

  echo "align ok"

foobar()


#----------------------------------------------------------------
# Aligned allocation

type
  MyType16 = object
    a {.align(16).}: int

const qtys = 100..500 # covers small and big chunks of allocator 

var x: array[10, ptr MyType16]
for q in qtys:
  for i in 0..<x.len:
    x[i] = create(MyType16, q)
    doAssert(cast[int](x[i]) mod alignof(MyType16) == 0)
  for i in 0..<x.len:
    dealloc(x[i])


type
  MyType32  = object
    a{.align(32).}: int

var y: array[10, ptr MyType32]
for q in qtys:
  for i in 0..<y.len:
    y[i] = create(MyType32, q)
    doAssert(cast[int](y[i]) mod alignof(MyType32) == 0)
  for i in 0..<y.len:
    dealloc(y[i])



type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

var z: array[10, ptr m256d]
for q in qtys:
  for i in 0..<z.len:
    z[i] = create(m256d, q)
    doAssert(cast[int](z[i]) mod alignof(m256d) == 0)
  for i in 0..<y.len:
    dealloc(z[i])
