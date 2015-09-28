type
  bits* = object
    flag* {.bitsize: 1.}: cint
    opts* {.bitsize: 4.}: cint

var b: bits
echo b.flag
