discard """
output: '''
success
M1 M2
ok
'''
"""

type
  TObj = object
    x, y: int
  PObj = ref TObj

proc p(a: PObj) =
  a.x = 0

proc q(a: var PObj) =
  a.p()

var
  a: PObj
new(a)
q(a)

# bug #914
when defined(windows):
  var x = newWideCString("Hello")

echo "success"


# bug #833

type
  PFuture*[T] = ref object
    value*: T
    finished*: bool
    cb: proc (future: PFuture[T]) {.closure.}

var k = PFuture[void]()


##bug #9297 and #13281

import strutils

type
  MyKind = enum
    M1, M2, M3

  MyObject {.exportc: "ExtObject"} = object
    case kind: MyKind
      of M1: a:int
      of M2: b:float
      of M3: c:cstring

  MyObjectRef {.exportc: "ExtObject2"} = ref object
    case kind: MyKind
      of M1: a:int
      of M2: b:float
      of M3: c:cstring

  Helper* {.exportc: "PublicHelper".} = object
    case isKind: bool
      of true:
        formatted: string
      of false:
        parsed1: string
        parsed2: string

proc newMyObject(kind: MyKind, val: string): MyObject =
  result = MyObject(kind: kind)

  case kind
    of M1: result.a = parseInt(val)
    of M2: result.b = parseFloat(val)
    of M3: result.c = val

proc newMyObjectRef(kind: MyKind, val: string): MyObjectRef =
  result = MyObjectRef(kind: kind)
  case kind
    of M1: result.a = parseInt(val)
    of M2: result.b = parseFloat(val)
    of M3: result.c = val


echo newMyObject(M1, "2").kind, " ", newMyObjectRef(M2, "3").kind


proc test(c: Helper): string =
  c.formatted

echo test(Helper(isKind: true, formatted: "ok"))


# bug #19613

type
  Eth2Digest = object
    data: array[42, byte]

  BlockId* = object
    root*: Eth2Digest

  BlockSlotId* = object
    bid*: BlockId
    slot*: uint64

func init*(T: type BlockSlotId, bid: BlockId, slot: uint64): T =
  #debugecho "init ", bid, " ", slot
  BlockSlotId(bid: bid, slot: slot)

proc bug19613 =
  var x: BlockSlotId
  x.bid.root.data[0] = 42

  x =
    if x.slot > 0:
      BlockSlotId.init(x.bid, x.slot)
    else:
      BlockSlotId.init(x.bid, x.slot)
  doAssert x.bid.root.data[0] == 42

bug19613()
