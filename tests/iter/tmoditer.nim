discard """
  output: "XXXXX01234"
"""

iterator modPairs(a: var array[0..4,string]): tuple[key: int, val: var string] =
  for i in 0..a.high:
    yield (key: i, val: a[i])

iterator modItems*[T](a: var array[0..4,T]): var T =
  for i in 0..a.high:
    yield a[i]

var
  arr = ["a", "b", "c", "d", "e"]

for a in modItems(arr):
  a = "X"

for a in items(arr):
  stdout.write(a)

for i, a in modPairs(arr):
  a = $i

for a in items(arr):
  stdout.write(a)

echo ""

#--------------------------------------------------------------------
# Lent iterators
#--------------------------------------------------------------------
type
  NonCopyable = object
    x: int


proc `=destroy`(o: var NonCopyable) =
  discard

proc `=copy`(dst: var NonCopyable, src: NonCopyable) {.error.}

proc `=sink`(dst: var NonCopyable, src: NonCopyable) =
  dst.x = src.x

iterator lentItems[T](a: openArray[T]): lent T =
  for i in 0..a.high:
    yield a[i]

iterator lentPairs[T](a: array[0..1, T]): tuple[key: int, val: lent T] =
  for i in 0..a.high:
    yield (key: i, val: a[i])


let arr1 = [1, 2, 3]
let arr2 = @["a", "b", "c"]
let arr3 = [NonCopyable(x: 1), NonCopyable(x: 2)]
let arr4 = @[(1, "a"), (2, "b"), (3, "c")]

var accum: string
for x in lentItems(arr1):
  accum &= $x
doAssert(accum == "123")

accum = ""
for x in lentItems(arr2):
  accum &= $x
doAssert(accum == "abc")

accum = ""
for val in lentItems(arr3):
  accum &= $val.x
doAssert(accum == "12")

accum = ""
for i, val in lentPairs(arr3):
  accum &= $i & "-" & $val.x & " "
doAssert(accum == "0-1 1-2 ")

accum = ""
for i, val in lentItems(arr4):
  accum &= $i & "-" & $val & " "
doAssert(accum == "1-a 2-b 3-c ")

accum = ""
for (i, val) in lentItems(arr4):
  accum &= $i & "-" & $val & " "
doAssert(accum == "1-a 2-b 3-c ")
