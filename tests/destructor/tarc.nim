discard """
  output: '''
@[1, 2, 3]
Success
@["a", "b", "c"]
Hello
1
2
0
List
@["4", "5", "6", "", "", "a", ""]
@["", "", "a", ""]
'''
  cmd: '''nim c --gc:arc $file'''
"""

import os
import math
import lists
import strutils

proc mkleak() =
  # allocate 1 MB via linked lists
  let numberOfLists = 100
  for i in countUp(1, numberOfLists):
    var leakList = initDoublyLinkedList[string]()
    let numberOfLeaks = 5000
    for j in countUp(1, numberOfLeaks):
      leakList.append(newString(200))

proc mkManyLeaks() =
  for i in 0..0:
    mkleak()
  echo "Success"

iterator foobar(c: string): seq[string] {.closure.} =
  yield @["a", "b", c]

proc tsimpleClosureIterator =
  var myc = "c"
  for it in foobar(myc):
    echo it

type
  LazyList = ref object
    c: proc() {.closure.}

proc tlazyList =
  let dep = @[1, 2, 3]
  var x = LazyList(c: proc () = echo(dep))
  x.c()

type
  Foo = ref object

proc tleakingNewStmt =
  var x: Foo
  for i in 0..10:
    new(x)

iterator infinite(): int {.closure.} =
  var i = 0
  while true:
    yield i
    inc i

iterator take(it: iterator (): int, numToTake: int): int {.closure.} =
  var i = 0
  for x in it():
    if i >= numToTake:
      break
    yield x
    inc i

proc take3 =
  for x in infinite.take(3):
    discard


type
  A = ref object of RootObj
    x: int

  B = ref object of A
    more: string

proc inheritanceBug(param: string) =
  var s: (A, A)
  s[0] = B(more: "a" & param)
  s[1] = B(more: "a" & param)


type
  PAsyncHttpServer = ref object
    value: string

proc serve(server: PAsyncHttpServer) = discard

proc leakObjConstr =
  serve(PAsyncHttpServer(value: "asdas"))

let startMem = getOccupiedMem()
take3()
tlazyList()
inheritanceBug("whatever")
mkManyLeaks()
tsimpleClosureIterator()
tleakingNewStmt()
leakObjConstr()

# bug #12964

type
  Token* = ref object of RootObj
  Li* = ref object of Token

proc bug12964*() =
  var token = Li()
  var tokens = @[Token()]
  tokens.add token

bug12964()

# bug #13119
import streams

proc bug13119 =
  var m = newStringStream("Hello world")
  let buffer = m.readStr(5)
  echo buffer
  m.close

bug13119()

# bug #13105

type
  Result[T, E] = object
    a: T
    b: E
  D = ref object
    x: int
  R = Result[D, int]

proc bug13105 =
  for n in [R(b: 1), R(b: 2)]:
    echo n.b

bug13105()

echo getOccupiedMem() - startMem


#------------------------------------------------------------------------------
# issue #14294

import tables

type
  TagKind = enum
    List = 0, Compound

  Tag = object
    case kind: TagKind
    of List:
      values: seq[Tag]
    of Compound:
      compound: Table[string, Tag]

var a = Tag(kind: List)
var b = a
echo a.kind
var c = a

proc testAdd(i: int; yyy: openArray[string]) =
  var x: seq[string]
  x.add [$i, $(i+1), $(i+2)]
  x.add yyy
  echo x

var y = newSeq[string](4)
y[2] = "a"
testAdd(4, y)
echo y
