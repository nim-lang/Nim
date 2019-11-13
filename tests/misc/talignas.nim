discard """
ccodeCheck: "\\i @'alignas(128) NI mylocal1' .*"
target: "c cpp"
output: "alignas ok"
"""

# This is for Azure. The keyword ``alignof`` only exists in ``c++11``
# and newer. On Azure gcc does not default to c++11 yet.
when defined(cpp) and not defined(windows):
  {.passC: "-std=c++11".}

import globalalignas

var toplevel1 {.alignas: 32.} : int32
var toplevel2 {.alignas: 32.} : int32
var toplevel3 {.alignas: 32.} : int32

proc foobar() =
  var myvar1 {.global, alignas(64).}: int = 123
  var myvar2 {.global, alignas(64).}: int = 123
  var myvar3 {.global, alignas(64).}: int = 123

  doAssert (cast[uint](addr(myglobal1)) and 127) == 0
  doAssert (cast[uint](addr(myglobal2)) and 127) == 0
  doAssert (cast[uint](addr(myglobal3)) and 127) == 0

  doAssert (cast[uint](addr(myvar1)) and 63) == 0
  doAssert (cast[uint](addr(myvar2)) and 63) == 0
  doAssert (cast[uint](addr(myvar3)) and 63) == 0

  doAssert (cast[uint](addr(toplevel1)) and 31) == 0
  doAssert (cast[uint](addr(toplevel2)) and 31) == 0
  doAssert (cast[uint](addr(toplevel3)) and 31) == 0

  # test multiple alignas expressions
  var mylocal1 {.alignas(0), alignas(128), alignas(32).}: int = 123
  var mylocal2 {.alignas(128), alignas(0), alignas(32).}: int = 123
  var mylocal3 {.alignas(0), alignas(32), alignas(128).}: int = 123

  doAssert (cast[uint](addr(mylocal1)) and 127) == 0
  doAssert (cast[uint](addr(mylocal2)) and 127) == 0
  doAssert (cast[uint](addr(mylocal3)) and 127) == 0

  echo "alignas ok"

foobar()
