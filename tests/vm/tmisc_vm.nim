discard """
  output: '''[127, 127, 0, 255]
[127, 127, 0, 255]

(data: 1)
'''

  nimout: '''caught Exception
main:begin
main:end
@[{0}]
(width: 0, height: 0, path: "")
@[(width: 0, height: 0, path: ""), (width: 0, height: 0, path: "")]
Done!
foo4
foo4
foo4
(a: 0, b: 0)
(a: 0, b: 0)
(a: 0, b: 0)
'''
"""

#bug #1009
type
  TAggRgba8* = array[4, byte]

template R*(self: TAggRgba8): byte = self[0]
template G*(self: TAggRgba8): byte = self[1]
template B*(self: TAggRgba8): byte = self[2]
template A*(self: TAggRgba8): byte = self[3]

template `R=`*(self: TAggRgba8, val: byte) =
  self[0] = val
template `G=`*(self: TAggRgba8, val: byte) =
  self[1] = val
template `B=`*(self: TAggRgba8, val: byte) =
  self[2] = val
template `A=`*(self: TAggRgba8, val: byte) =
  self[3] = val

proc ABGR*(val: int | int64): TAggRgba8 =
  var V = val
  result.R = byte(V and 0xFF)
  V = V shr 8
  result.G = byte(V and 0xFF)
  V = V shr 8
  result.B = byte(V and 0xFF)
  result.A = byte((V shr 8) and 0xFF)

const
  c1 = ABGR(0xFF007F7F)
echo ABGR(0xFF007F7F).repr, c1.repr


# bug 8740

static:
  try:
    raise newException(ValueError, "foo")
  except Exception:
    echo "caught Exception"
  except Defect:
    echo "caught Defect"
  except ValueError:
    echo "caught ValueError"

# bug #10538

block:
  proc fun1(): seq[int] =
    try:
      try:
        result.add(1)
        return
      except:
        result.add(-1)
      finally:
        result.add(2)
    finally:
      result.add(3)
    result.add(4)

  let x1 = fun1()
  const x2 = fun1()
  doAssert(x1 == x2)

# bug #11610
proc simpleTryFinally()=
  try:
    echo "main:begin"
  finally:
    echo "main:end"

static: simpleTryFinally()

# bug #10981

import sets

proc main =
  for i in 0..<15:
    var someSets = @[initHashSet[int]()]
    someSets[^1].incl(0) # <-- segfaults
    if i == 0:
      echo someSets

static:
  main()

# bug #7261
const file = """
sprites.png
size: 1024,1024
format: RGBA8888
filter: Linear,Linear
repeat: none
char/slide_down
  rotate: false
  xy: 730, 810
  size: 204, 116
  orig: 204, 116
  offset: 0, 0
  index: -1
"""

type
  AtlasPage = object
    width, height: int
    path: string

  CtsStream = object
    data: string
    pos: int

proc atEnd(stream: CtsStream): bool =
  stream.pos >= stream.data.len

proc readChar(stream: var CtsStream): char =
  if stream.atEnd:
    result = '\0'
  else:
    result = stream.data[stream.pos]
    inc stream.pos

proc readLine(s: var CtsStream, line: var string): bool =
  # This is pretty much copied from the standard library:
  line.setLen(0)
  while true:
    var c = readChar(s)
    if c == '\c':
      c = readChar(s)
      break
    elif c == '\L': break
    elif c == '\0':
      if line.len > 0: break
      else: return false
    line.add(c)
  result = true

proc peekLine(s: var CtsStream, line: var string): bool =
  let oldPos = s.pos
  result = s.readLine(line)
  s.pos = oldPos

proc initCtsStream(data: string): CtsStream =
  CtsStream(
    pos: 0,
    data: data
  )

# ********************
# Interesting stuff happens here:
# ********************

proc parseAtlas(stream: var CtsStream) =
  var pages = @[AtlasPage(), AtlasPage()]
  var line = ""

  block:
    let page = addr pages[^1]
    discard stream.peekLine(line)
    discard stream.peekLine(line)
    echo page[]
  echo pages

static:
  var stream = initCtsStream(file)
  parseAtlas(stream)
  echo "Done!"


# bug #12244

type
  Apple = object
    data: int

func what(x: var Apple) =
  x = Apple(data: 1)

func oh_no(): Apple =
  what(result)

const
  vmCrash = oh_no()

debugEcho vmCrash


# bug #12310

proc someTransform(s: var array[8, uint64]) =
  var s1 = 5982491417506315008'u64
  s[1] += s1

static:
  var state: array[8, uint64]
  state[1] = 7105036623409894663'u64
  someTransform(state)

  doAssert state[1] == 13087528040916209671'u64

import macros
# bug #12670

macro fooImpl(arg: untyped) =
  result = quote do:
    `arg`

proc foo(): string {.compileTime.} =
  fooImpl:
    result = "foo"
    result.addInt 4

static:
  echo foo()
  echo foo()
  echo foo()

# bug #12488
type
  MyObject = object
    a,b: int
  MyObjectRef = ref MyObject

static:
  let x1 = new(MyObject)
  echo x1[]
  let x2 = new(MyObjectRef)
  echo x2[]
  let x3 = new(ref MyObject) # cannot generate VM code for ref MyObject
  echo x3[]
