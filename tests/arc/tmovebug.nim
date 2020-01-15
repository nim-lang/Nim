discard """
  cmd: "nim c --gc:arc $file"
  output: '''5'''
"""

# move bug
type
  TMyObj = object
    p: pointer
    len: int

var destroyCounter = 0

proc `=destroy`(o: var TMyObj) =
  if o.p != nil:
    dealloc o.p
    o.p = nil
    inc destroyCounter

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

proc use(a: TCaseObj) = discard

proc moveBug(i: var int) =
  var a: array[2, TCaseObj]
  a[i] = TCaseObj(kind: A, x1: 5000, x2: TMyObj(len: 5, p: alloc(5))) # 1
  a[i+1] = a[i] # 2
  inc i
  use(a[i-1])

var x = 0
moveBug(x)

proc moveBug2(): (TCaseObj, TCaseObj) =
  var a: array[2, TCaseObj]
  a[0] = TCaseObj(kind: A, x1: 5000, x2: TMyObj(len: 5, p: alloc(5)))
  a[1] = a[0] # can move 3
  result[0] = TCaseObj(kind: A, x1: 5000, x2: TMyObj(len: 5, p: alloc(5))) # 4
  result[1] = result[0] # 5

proc main =
  discard moveBug2()

main()
echo destroyCounter
