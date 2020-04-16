discard """
  cmd: "nim c --gc:arc --exceptions:goto --panics:off $file"
  output: '''prevented!
caught
AssertionError
900'''
"""

type
  E = enum
    kindA, kindB
  Obj = object
    case kind: E
    of kindA: s: string
    of kindB: i: int

  ObjA = ref object of RootObj
  ObjB = ref object of ObjA

proc takeRange(x: range[0..4]) = discard

proc bplease(x: ObjB) = discard

proc helper = doAssert(false)

proc main(i: int) =
  var obj = Obj(kind: kindA, s: "abc")
  obj.kind = kindB
  obj.i = 2
  try:
    var objA = ObjA()
    bplease(ObjB(objA))
  except ObjectConversionError:
    echo "prevented!"

  try:
    takeRange(i)
  except RangeError:
    echo "caught"

  try:
    helper()
  except AssertionError:
    echo "AssertionError"

  echo i * i

main(30)
