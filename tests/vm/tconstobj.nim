discard """
  output: '''
(name: "hello")
(-1, 0)
(FirstName: "James", LastName: "Franco")
[1, 2, 3]
'''
"""

# bug #2774, bug #3195
type Foo = object
  name: string

const fooArray = [
  Foo(name: "hello")
]

echo fooArray[0]

type
    Position = object
        x, y: int

proc `$`(pos: Position): string =
    result = "(" & $pos.x & ", " & $pos.y & ")"

proc newPos(x, y: int): Position =
    result = Position(x: x, y: y)

const
     offset: array[1..4, Position] = [
         newPos(-1, 0),
         newPos(1, 0),
         newPos(0, -1),
         newPos(0, 1)
     ]

echo offset[1]

# bug #1547
import tables

type Person* = object
    FirstName*: string
    LastName*: string

let people = {
    "001": Person(FirstName: "James", LastName: "Franco")
}.toTable()

echo people["001"]

# Object downconversion should not copy

type
  SomeBaseObj  {.inheritable.} = object of RootObj
    txt : string
  InheritedFromBase = object of SomeBaseObj
    other : string

proc initBase(sbo: var SomeBaseObj) =
  sbo.txt = "Initialized string from base"

static:
  var ifb2: InheritedFromBase
  initBase(SomeBaseObj(ifb2))
  echo repr(ifb2)
  doAssert(ifb2.txt == "Initialized string from base")

static: # issue #11861
  var ifb2: InheritedFromBase
  initBase(ifb2)
  doAssert(ifb2.txt == "Initialized string from base")


static: # issue #15662
  proc a(T: typedesc) = echo T.type
  a((int, int))

# bug #16069
type
  E = enum
    val1, val2
  Obj = object
    case k: E
    of val1:
      x: array[3, int]
    of val2:
      y: uint32

const
  foo = [1, 2, 3]
  arr = Obj(k: val1, x: foo)

echo arr.x
