discard """
ccodeCheck: "\\i @'unsigned int flag:1;' .*"
"""

type
  bits* = object
    flag* {.bitsize: 1.}: cuint
    opts* {.bitsize: 4.}: cint

var
  b: bits

assert b.flag == 0
b.flag = 1
assert b.flag == 1
b.flag = 2
assert b.flag == 0

b.opts = 7
assert b.opts == 7
b.opts = 9
assert b.opts == -7
