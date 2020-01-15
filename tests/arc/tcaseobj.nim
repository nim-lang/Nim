discard """
  cmd: "nim c --gc:arc $file"
  output: '''myobj destroyed
myobj destroyed
myobj destroyed
myobj destroyed
'''
"""

# bug #13102

type
  D = ref object
  R = object
    case o: bool
    of false:
      discard
    of true:
      field: D

iterator things(): R =
  when true:
    var
      unit = D()
    while true:
      yield R(o: true, field: unit)
  else:
    while true:
      var
        unit = D()
      yield R(o: true, field: unit)

proc main =
  var i = 0
  for item in things():
    discard item.field
    inc i
    if i == 2: break

main()

# bug #13149

type
  TMyObj = object
    p: pointer
    len: int

proc `=destroy`(o: var TMyObj) =
  if o.p != nil:
    dealloc o.p
    o.p = nil
    echo "myobj destroyed"

proc `=`(dst: var TMyObj, src: TMyObj) =
  `=destroy`(dst)
  dst.p = alloc(src.len)
  dst.len = src.len

proc `=sink`(dst: var TMyObj, src: TMyObj) =
  `=destroy`(dst)
  dst.p = src.p
  dst.len = src.len

type
  TObjKind = enum Z, A, B
  TCaseObj = object
    case kind: TObjKind
    of Z: discard
    of A:
      x1: int # this int plays important role
      x2: TMyObj
    of B:
      y: TMyObj

proc testSinks: TCaseObj =
  result = TCaseObj(kind: A, x1: 5000, x2: TMyObj(len: 5, p: alloc(5)))
  result = TCaseObj(kind: B, y: TMyObj(len: 3, p: alloc(3)))

proc use(x: TCaseObj) = discard

proc testCopies(i: int) =
  var a: array[2, TCaseObj]
  a[i] = TCaseObj(kind: A, x1: 5000, x2: TMyObj(len: 5, p: alloc(5)))
  a[i+1] = a[i] # copy, cannot move
  use(a[i])

let x1 = testSinks()
testCopies(0)
