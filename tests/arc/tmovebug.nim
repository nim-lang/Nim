discard """
  cmd: "nim c --gc:arc $file"
  output: '''5
(w: 5)
(w: -5)
c.text = hello
c.text = hello
p.text = hello
p.toks = @["hello"]
c.text = hello
c[].text = hello
pA.text = hello
pA.toks = @["hello"]
c.text = hello
c.text = hello
pD.text = hello
pD.toks = @["hello"]
c.text = hello
c.text = hello
pOD.text = hello
pOD.toks = @["hello"]
'''
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

# bug #13314

type
  O = object
    v: int
  R = ref object
    w: int

proc `$`(r: R): string = $r[]

proc tbug13314 =
  var t5 = R(w: 5)
  var execute = proc () =
    echo t5

  execute()
  t5.w = -5
  execute()

tbug13314()

#-------------------------------------------------------------------------
# bug #13368

import strutils
proc procStat() =
  for line in @["a b", "c d", "e f"]:
    let cols = line.splitWhitespace(maxSplit=1)
    let x = cols[0]
    let (nm, rest) = (cols[0], cols[1])
procStat()


# bug #14269

import sugar, strutils

type
  Cursor = object
    text: string
  Parsed = object
    text: string
    toks: seq[string]

proc tokenize(c: var Cursor): seq[string] =
  dump c.text
  return c.text.splitWhitespace()

proc parse(): Parsed =
  var c = Cursor(text: "hello")
  dump c.text
  return Parsed(text: c.text, toks: c.tokenize) # note: c.tokenized uses c.text

let p = parse()
dump p.text
dump p.toks


proc tokenizeA(c: ptr Cursor): seq[string] =
  dump c[].text
  return c[].text.splitWhitespace()

proc parseA(): Parsed =
  var c = Cursor(text: "hello")
  dump c.text
  return Parsed(text: c.text, toks: c.addr.tokenizeA) # note: c.tokenized uses c.text

let pA = parseA()
dump pA.text
dump pA.toks


proc tokenizeD(c: Cursor): seq[string] =
  dump c.text
  return c.text.splitWhitespace()

proc parseD(): Parsed =
  var c = cast[ptr Cursor](alloc0(sizeof(Cursor)))
  c[] = Cursor(text: "hello")
  dump c.text
  return Parsed(text: c.text, toks: c[].tokenizeD) # note: c.tokenized uses c.text

let pD = parseD()
dump pD.text
dump pD.toks

# Bug would only pop up with owned refs
proc tokenizeOD(c: Cursor): seq[string] =
  dump c.text
  return c.text.splitWhitespace()

proc parseOD(): Parsed =
  var c = new Cursor
  c[] = Cursor(text: "hello")
  dump c.text
  return Parsed(text: c.text, toks: c[].tokenizeOD) # note: c.tokenized uses c.text

let pOD = parseOD()
dump pOD.text
dump pOD.toks

when false:
  # Bug would only pop up with owned refs and implicit derefs, but since they don't work together..
  {.experimental: "implicitDeref".}
  proc tokenizeOHD(c: Cursor): seq[string] =
    dump c.text
    return c.text.splitWhitespace()

  proc parseOHD(): Parsed =
    var c = new Cursor
    c[] = Cursor(text: "hello")
    dump c.text
    return Parsed(text: c.text, toks: c.tokenizeOHD) # note: c.tokenized uses c.text

  let pOHD = parseOHD()
  dump pOHD.text
  dump pOHD.toks
