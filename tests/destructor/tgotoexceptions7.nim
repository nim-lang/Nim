discard """
  cmd: "nim c --gc:arc --exceptions:goto --panics:off $file"
  output: '''
field error prevented
prevented!
caught
AssertionDefect
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
  try:
    obj.kind = kindB
  except FieldDefect:
    echo "field error prevented"
  try:
    var objA = ObjA()
    bplease(ObjB(objA))
  except ObjectConversionDefect:
    echo "prevented!"

  try:
    takeRange(i)
  except RangeDefect:
    echo "caught"

  try:
    helper()
  except AssertionDefect:
    echo "AssertionDefect"

  echo i * i

main(30)
