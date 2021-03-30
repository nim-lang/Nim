discard """
  output: '''obj = (inner: (kind: Just, id: 7))
obj.inner.id = 7
id = 7
obj = (inner: (kind: Just, id: 7))
2
(a: "a", b: "b", c: "")
caught
(a: "a", b: "b", c: "")'''
"""

# bug #6960

import sugar
type
  Kind = enum None, Just, Huge
  Inner = object
    case kind: Kind
    of None: discard
    of Just: id: int
    of Huge: a,b,c,d,e,f: string
  Outer = object
    inner: Inner


proc shouldDoNothing(id: int): Inner =
  dump id
  Inner(kind: Just, id: id)

var obj = Outer(inner: Inner(kind: Just, id: 7))
dump obj
dump obj.inner.id
obj.inner = shouldDoNothing(obj.inner.id)
dump obj

import os

type
  TStatusEnum* = enum
    sUnknown = -1, sBuildFailure, sBuildInProgress, sBuildSuccess,
    sTestFailure, sTestInProgress, sTestSuccess, # ORDER MATTERS!
    sDocGenFailure, sDocGenInProgress, sDocGenSuccess,
    sCSrcGenFailure, sCSrcGenInProgress, sCSrcGenSuccess

  TStatus* = object
    status*: TStatusEnum
    desc*: string
    hash*: string

proc initStatus*(): TStatus =
  result.status = sUnknown
  result.desc = ""
  result.hash = ""

proc isInProgress*(status: TStatusEnum): bool =
  return status in {sBuildInProgress, sTestInProgress, sDocGenInProgress,
                    sCSrcGenInProgress}

proc `$`*(status: TStatusEnum): string =
  case status
  of sBuildFailure:
    return "build failure"
  of sBuildInProgress:
    return "build in progress"
  of sBuildSuccess:
    return "build finished"
  of sTestFailure:
    return "testing failure"
  of sTestInProgress:
    return "testing in progress"
  of sTestSuccess:
    return "testing finished"
  of sDocGenFailure:
    return "documentation generation failed"
  of sDocGenInProgress:
    return "generating documentation"
  of sDocGenSuccess:
    return "documentation generation succeeded"
  of sCSrcGenFailure:
    return "csource generation failed"
  of sCSrcGenInProgress:
    return "csource generation in progress"
  of sCSrcGenSuccess:
    return "csource generation succeeded"
  of sUnknown:
    return "unknown"

proc makeCommitPath*(platform, hash: string): string =
  return platform / "nim_" & hash.substr(0, 11) # 11 Chars.

type
  TFlag = enum
    A, B, C, D

  TFlags = set[TFlag]

  TObj = object
    x: int
    flags: TFlags

# have a proc taking TFlags as param and returning object having TFlags field
proc foo(flags: TFlags): TObj = nil


# bug #5137
type
  MyInt {.importc: "int".} = object
  MyIntDistinct = distinct MyInt

proc bug5137(d: MyIntDistinct) =
  discard d.MyInt

#-------------------------------------
# bug #8979

type
  MyKind = enum
    Fixed, Float

  MyObject = object
    someInt: int
    case kind: MyKind
      of Float: index: string
      of Fixed: nil

  MyResult = object
    val: array[0..1, string]
    vis: set[0..1]

import macros

func myfunc(obj: MyObject): MyResult {.raises: [].} =
  template index: auto =
    case obj.kind:
      of Float: $obj.index
      of Fixed: "Fixed"
  macro to_str(a: untyped): string =
    result = newStrLitNode(a.repr)
  result.val[0] = index
  result.val[1] = to_str(obj.kind + Ola)

let x = MyObject(someInt: 10, kind: Fixed)
echo myfunc(x).val.len

# bug #14126

type X = object
  a, b, c: string

proc f(): X =
  result.a = "a"
  result.b = "b"
  raise (ref ValueError)()

proc ohmanNoNRVO =
  var x: X
  x.a = "1"
  x.b = "2"
  x.c = "3"

  try:
    x = f()
  except:
    discard

  echo x
  # once NVRO is sorted out, x.c == "3"
  doAssert x.c == "", "shouldn't modify x if f raises"

ohmanNoNRVO()

proc ohmanNoNRVO2(x: var X) =
  x.a = "1"
  x.c = "3"
  x = f()

var xgg: X
try:
  ohmanNoNRVO2(xgg)
except:
  echo "caught"
echo xgg
# once NVRO is sorted out, xgg.c == "3"
doAssert xgg.c == "", "this assert will fail"
