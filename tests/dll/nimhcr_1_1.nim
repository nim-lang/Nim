
echo "   1: print me once!"

import hotcodereloading

let g_1* = 8 # devilish!

proc f_1*(): int =
  var a {.global.} = 1
  a.inc
  return a


# all these constructs should compile
let some_glob_1 = 1
echo "   1: ", some_glob_1
if true:
  let some_glob_2 = 2
  echo "   1: ", some_glob_2
  if true:
    let some_glob_3 = 3
    echo "   1: ", some_glob_3
block:
  let some_glob_4 = 4
  proc inBlock(num: int) =
    echo "   1: ", num
  inBlock(some_glob_4)
var counter = 3
while counter > 0:
  let some_glob_5 = 5
  echo "   1: ", some_glob_5
  counter.dec

type
  Type1 = object
    a: int
    b: int
var t = Type1(a: 42, b: 11)
echo "   1: Type1.a:", t.a

type
  obj = ref object
    dat: int
    str: string

proc foo(): (int, obj) = (1, obj(dat: 3, str: "bar"))

let (aa, bb) = foo()
afterCodeReload:
  echo aa
  echo bb.str
