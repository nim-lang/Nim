discard """
  targets: "c cpp js"
  output: '''
Sub2
Sub1
fallback
child
base
77
again
right
5
'''
"""

type
  Base = ref object of RootObj
  Sub1 = ref object of Base
    a: int
  Sub2 = ref object of Base
    b: string
  Sub3 = ref object of Base

  BranchBase = ref object of RootObj
  Left = ref object of BranchBase
  Right = ref object of BranchBase
  LeftLeaf = ref object of Left
  RightLeaf = ref object of Right

  BaseObj {.inheritable.} = object of RootObj
    a: int
  SubObj = object of BaseObj
    b: int

var onlyOne = 0

proc getObj: Base =
  inc onlyOne
  Sub3()

case getObj()
of Sub1:
  discard
of Sub2:
  discard
of Sub3:
  discard

doAssert onlyOne == 1

proc classify(x: Base): string =
  case x
  of Sub1 as s1:
    doAssert s1.a == 11
    "Sub1"
  of Sub2 as s2:
    doAssert s2.b == "ok"
    "Sub2"
  else:
    "fallback"

proc family(x: Base): string =
  case x
  of Sub1, Sub2:
    "child"
  else:
    "base"

proc widen(x: Base): string =
  case x
  of Sub1:
    "sub1"
  of Base as bx:
    doAssert bx of Base
    "base"
  else:
    "fallback"

proc mutate(x: Base) =
  case x
  of Sub1 as s1:
    s1.a = 77
  else:
    discard

var x: Base = Sub2(b: "ok")
echo classify(x)

x = Sub1(a: 11)
echo classify(x)

x = nil
echo classify(x)

echo family(Sub1(a: 22))
echo widen(Base())

x = Sub1(a: 1)
mutate(x)
echo Sub1(x).a

echo(
  case Base(Sub2(b: "again"))
  of Sub1 as s1:
    $s1.a
  of Sub2 as s2:
    s2.b
  else:
    "bad"
)

echo(
  case BranchBase(RightLeaf())
  of LeftLeaf:
    "wrong"
  of RightLeaf:
    "right"
  else:
    "bad"
)

block:
  var s = SubObj(a: 4, b: 5)
  let p: ptr BaseObj = addr s
  echo(
    case p
    of ptr SubObj as sp:
      $sp.b
    else:
      "bad"
  )
  doAssert s.b == 5
