discard """
ccodeCheck: "\\i @'unsigned int flag:1;' .*"
"""

type
  bits* = object
    flag* {.bitsize: 1.}: cuint
    opts* {.bitsize: 4.}: cint

var
  b: bits

doAssert b.flag == 0
b.flag = 1
doAssert b.flag == 1
b.flag = 2
doAssert b.flag == 0

b.opts = 7
doAssert b.opts == 7
b.opts = 9
doAssert b.opts == -7
