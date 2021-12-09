discard """
  output: '''
123xyzabc
destroyed: false
destroyed: false
destroyed2: false
destroyed2: false
destroying variable: 2
destroying variable: 1
whiley ends :(
1
(x: "0")
(x: "1")
(x: "2")
(x: "3")
(x: "4")
(x: "5")
(x: "6")
(x: "7")
(x: "8")
(x: "9")
(x: "10")
0
new line before - @['a']
new line after - @['a']
finalizer
aaaaa
hello
ok
true
copying
123
42
closed
destroying variable: 20
destroying variable: 10
'''
  cmd: "nim c --gc:arc --deepcopy:on -d:nimAllocPagesViaMalloc $file"
"""

proc takeSink(x: sink string): bool = true

proc b(x: sink string): string =
  if takeSink(x):
    return x & "abc"

proc bbb(inp: string) =
  let y = inp & "xyz"
  echo b(y)

bbb("123")


# bug #13691
type Variable = ref object
  value: int

proc `=destroy`(self: var typeof(Variable()[])) =
  echo "destroying variable: ",self.value

proc newVariable(value: int): Variable =
  result = Variable()
  result.value = value
  #echo "creating variable: ",result.value

proc test(count: int) =
  var v {.global.} = newVariable(10)

  var count = count - 1
  if count == 0: return

  test(count)
  echo "destroyed: ", v.isNil

test(3)

proc test2(count: int) =
  #block: #XXX: Fails with block currently
    var v {.global.} = newVariable(20)

    var count = count - 1
    if count == 0: return

    test2(count)
    echo "destroyed2: ", v.isNil

test2(3)

proc whiley =
  var a = newVariable(1)
  while true:
    var b = newVariable(2)
    if true: raise newException(CatchableError, "test")

try:
  whiley()
except CatchableError:
  echo "whiley ends :("

#------------------------------------------------------------------------------
# issue #13810

import streams

type
  A = ref AObj
  AObj = object of RootObj
    io: Stream
  B = ref object of A
    x: int

proc `=destroy`(x: var AObj) =
  close(x.io)
  echo "closed"

var x = B(io: newStringStream("thestream"))


#------------------------------------------------------------------------------
# issue #14003

proc cryptCTR*(nonce: var openArray[char]) =
  nonce[1] = 'A'

proc main() =
  var nonce1 = "0123456701234567"
  cryptCTR(nonce1)
  doAssert(nonce1 == "0A23456701234567")
  var nonce2 = "01234567"
  cryptCTR(nonce2.toOpenArray(0, nonce2.len-1))
  doAssert(nonce2 == "0A234567")

main()

# bug #14079
import std/algorithm

let
  n = @["c", "b"]
  q = @[("c", "2"), ("b", "1")]

doAssert n.sortedByIt(it) == @["b", "c"], "fine"
doAssert q.sortedByIt(it[0]) == @[("b", "1"), ("c", "2")], "fails under arc"


#------------------------------------------------------------------------------
# issue #14236

type
  MyType = object
    a: seq[int]

proc re(x: static[string]): static MyType =
  MyType()

proc match(inp: string, rg: static MyType) =
  doAssert rg.a.len == 0

match("ac", re"a(b|c)")

#------------------------------------------------------------------------------
# issue #14243

type
  Game* = ref object

proc free*(game: Game) =
  let a = 5

proc newGame*(): Game =
  new(result, free)

var game*: Game


#------------------------------------------------------------------------------
# issue #14333

type
  SimpleLoop = object

  Lsg = object
    loops: seq[ref SimpleLoop]
    root: ref SimpleLoop

var lsg: Lsg
lsg.loops.add lsg.root
echo lsg.loops.len

# bug #14495
type
  Gah = ref object
    x: string

proc bug14495 =
  var owners: seq[Gah]
  for i in 0..10:
    owners.add Gah(x: $i)

  var x: seq[Gah]
  for i in 0..10:
    x.add owners[i]

  for i in 0..100:
    setLen(x, 0)
    setLen(x, 10)

  for i in 0..x.len-1:
    if x[i] != nil:
      echo x[i][]

  for o in owners:
    echo o[]

bug14495()

# bug #14396
type
  Spinny = ref object
    t: ref int
    text: string

proc newSpinny*(): Spinny =
  Spinny(t: new(int), text: "hello")

proc spinnyLoop(x: ref int, spinny: sink Spinny) =
  echo x[]

proc start*(spinny: sink Spinny) =
  spinnyLoop(spinny.t, spinny)

var spinner1 = newSpinny()
spinner1.start()

# bug #14345

type
  SimpleLoopB = ref object
    children: seq[SimpleLoopB]
    parent: SimpleLoopB

proc addChildLoop(self: SimpleLoopB, loop: SimpleLoopB) =
  self.children.add loop

proc setParent(self: SimpleLoopB, parent: SimpleLoopB) =
  self.parent = parent
  self.parent.addChildLoop(self)

var l = SimpleLoopB()
l.setParent(l)


# bug #14968
import times
let currentTime = now().utc


# bug #14994
import sequtils
var newLine = @['a']
let indent = newSeq[char]()

echo "new line before - ", newline

newline.insert(indent, 0)

echo "new line after - ", newline

# bug #15044

type
  Test = ref object

proc test: Test =
  # broken
  new(result, proc(x: Test) =
    echo "finalizer"
  )

proc tdirectFinalizer =
  discard test()

tdirectFinalizer()


# bug #14480
proc hello(): int =
  result = 42

var leaves {.global.} = hello()
doAssert leaves == 42

# bug #15052

proc mutstrings =
  var data = "hello"
  for c in data.mitems():
    c = 'a'
  echo data

mutstrings()

# bug #15038

type
  Machine = ref object
    hello: string

var machineTypes: seq[tuple[factory: proc(): Machine]]

proc registerMachine(factory: proc(): Machine) =
  var mCreator = proc(): Machine =
    result = factory()

  machineTypes.add((factory: mCreator))

proc facproc(): Machine =
  result = Machine(hello: "hello")

registerMachine(facproc)

proc createMachine =
  for machine in machineTypes:
    echo machine.factory().hello

createMachine()

# bug #15122

import tables

type
  BENodeKind = enum
    tkBytes,
    tkList,
    tkDict

  BENode = object
    case kind: BENodeKind
    of tkBytes: strVal: string
    of tkList: listVal: seq[BENode]
    of tkDict: dictVal: Table[string, BENode]

var data = {
  "examples": {
    "values": BENode(
      kind: tkList,
      listVal: @[BENode(kind: tkBytes, strVal: "test")]
    )
  }.toTable()
}.toTable()

# For ARC listVal is empty for some reason
doAssert data["examples"]["values"].listVal[0].strVal == "test"




###############################################################################
# bug #15405
import parsexml
const test_xml_str = "<A><B>value</B></A>"
var stream = newStringStream(test_xml_str)
var xml: XmlParser
open(xml, stream, "test")
var xml2 = deepCopy(xml)

proc text_parser(xml: var XmlParser) =
  var test_passed = false
  while true:
    xml.next()
    case xml.kind
    of xmlElementStart:
      if xml.elementName == "B":
        xml.next()
        if xml.kind == xmlCharData and xml.charData == "value":
          test_passed = true

    of xmlEof: break
    else: discard
  xml.close()
  doAssert(test_passed)

text_parser(xml)
text_parser(xml2)

# bug #15599
type
  PixelBuffer = ref object

proc newPixelBuffer(): PixelBuffer =
  new(result) do (buffer: PixelBuffer):
    echo "ok"

discard newPixelBuffer()


# bug #17199

proc passSeq(data: seq[string]) =
  # used the system.& proc initially
  let wat = data & "hello"

proc test2 =
  let name = @["hello", "world"]
  passSeq(name)
  doAssert name == @["hello", "world"]

static: test2() # was buggy
test2()

proc merge(x: sink seq[string], y: sink string): seq[string] =
  newSeq(result, x.len + 1)
  for i in 0..x.len-1:
    result[i] = move(x[i])
  result[x.len] = move(y)

proc passSeq2(data: seq[string]) =
  # used the system.& proc initially
  let wat = merge(data, "hello")

proc test3 =
  let name = @["hello", "world"]
  passSeq2(name)
  doAssert name == @["hello", "world"]

static: test3() # was buggy
test3()

# bug #17712
proc t17712 =
  var ppv = new int
  discard @[ppv]
  var el: ref int
  el = [ppv][0]
  echo el != nil

t17712()

# bug #18030

type
  Foo = object
    n: int

proc `=copy`(dst: var Foo, src: Foo) =
  echo "copying"
  dst.n = src.n

proc `=sink`(dst: var Foo, src: Foo) =
  echo "sinking"
  dst.n = src.n

var a: Foo

proc putValue[T](n: T)

proc useForward =
  putValue(123)

proc putValue[T](n: T) =
  var b = Foo(n:n)
  a = b
  echo b.n

useForward()


# bug #17319
type
  BrokenObject = ref object
    brokenType: seq[int]

proc use(obj: BrokenObject) =
  discard

method testMethod(self: BrokenObject) {.base.} =
  iterator testMethodIter() {.closure.} =
    use(self)

  var nameIterVar = testMethodIter
  nameIterVar()

let mikasa = BrokenObject()
mikasa.testMethod()

# bug #19205
type
  InputSectionBase* = object of RootObj
    relocations*: seq[int]   # traced reference. string has a similar SIGSEGV.
  InputSection* = object of InputSectionBase

proc fooz(sec: var InputSectionBase) =
  if sec of InputSection:  # this line SIGSEGV.
    echo 42

var sec = create(InputSection)
sec[] = InputSection(relocations: newSeq[int]())
fooz sec[]
