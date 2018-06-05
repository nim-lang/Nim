discard """
  file: "tarray.nim"
  output: "100124"
"""
# simple check for one dimensional arrays

type
  TMyArray = array[0..2, int]
  TMyRecord = tuple[x, y: int]

proc sum(a: TMyarray): int =
  result = 0
  var i = 0
  while i < len(a):
    inc(result, a[i])
    inc(i)

proc sum(a: openarray[int]): int =
  result = 0
  var i = 0
  while i < len(a):
    inc(result, a[i])
    inc(i)

proc getPos(r: TMyRecord): int =
  result = r.x + r.y

write(stdout, sum([1, 2, 3, 4]))
write(stdout, sum([]))
write(stdout, getPos( (x: 5, y: 7) ))
#OUT 10012

# bug #1669
let filesToCreate = ["tempdir/fl1.a", "tempdir/fl2.b",
            "tempdir/tempdir2/fl3.e", "tempdir/tempdir2/tempdir3/fl4.f"]

var found: array[0..filesToCreate.high, bool]

echo found.len

# make sure empty arrays are assignable (bug #6853)
const arr1: array[0, int] = []
const arr2 = []
let arr3: array[0, string] = []

doAssert(arr1.len == 0)
doAssert(arr2.len == 0)
doAssert(arr3.len == 0)

# Negative array length is not allowed (#6852)
doAssert(not compiles(block:
  var arr: array[-1, int]))