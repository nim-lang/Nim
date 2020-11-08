template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

type
  Kind = enum k1 = 0, k2 = 33, k3 = 84, k4 = 278, k5 = 1000 # Holed enum work! #No they don't..
  KindObj = object
    case kind: Kind
    of k1, k2..k3: i32: int32
    of k4: f32: float32
    else: str: string

  IntObj = object
    case kind: uint8
    of low(uint8) .. 127: bad: string
    of 128'u8: neutral: string
    of 129 .. high(uint8): good: string

  OtherKind = enum ok1, ok2, ok3, ok4, ok5
  NestedKindObj = object
    case kind: Kind
    of k3, k5: discard
    of k2: str: string
    of k1, k4:
      case otherKind: OtherKind
      of ok1, ok2..ok3: i32: int32
      of ok4: f32: float32
      else: nestedStr: string

let kind = k4 # actual value should have no impact on the analysis.

accept: # Mimics the structure of the type. The optimial case.
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  of k4: discard KindObj(kind: kind, f32: 2.0)
  else: discard KindObj(kind: kind, str: "3")

accept: # Specifying the else explicitly is fine too.
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  of k4: discard KindObj(kind: kind, f32: 2.0)
  of k5: discard KindObj(kind: kind, str: "3")

accept:
  case kind
  of k1..k3, k5: discard
  else: discard KindObj(kind: kind, f32: 2.0)

accept:
  case kind
  of k4, k5: discard
  else: discard KindObj(kind: kind, i32: 1)

accept: # elif branches are ignored
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  of k4: discard KindObj(kind: kind, f32: 2.0)
  elif kind in {k1..k5}: discard
  else: discard KindObj(kind: kind, str: "3")

reject: # k4 conflicts with i32
  case kind
  of k1, k2, k3, k4: discard KindObj(kind: kind, i32: 1)
  else: discard KindObj(kind: kind, str: "3")

reject: # k4 is not caught, conflicts with str in the else branch
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  else: discard KindObj(kind: kind, str: "3")

reject: # elif branches are ignored
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  elif kind == k4: discard
  else: discard KindObj(kind: kind, str: "3")

let intKind = 29'u8

accept:
  case intKind
  of low(uint8) .. 127: discard IntObj(kind: intKind, bad: "bad")
  of 128'u8: discard IntObj(kind: intKind, neutral: "neutral")
  of 129 .. high(uint8): discard IntObj(kind: intKind, good: "good")

reject: # 0 leaks to else
  case intKind
  of low(uint8) .. 127: discard IntObj(kind: intKind, bad: "bad")
  of 129 .. high(uint8): discard IntObj(kind: intKind, good: "good")

accept:
  case intKind
  of low(uint8) .. 127: discard IntObj(kind: intKind, bad: "bad")
  of 128'u8: discard IntObj(kind: intKind, neutral: "neutral")
  of 139'u8, 140 .. high(uint8), 129'u8 .. 138'u8: discard IntObj(kind: intKind, good: "good")


accept:
  case kind
  of {k1, k2}, [k3]: discard KindObj(kind: kind, i32: 1)
  of k4: discard KindObj(kind: kind, f32: 2.0)
  else: discard KindObj(kind: kind, str: "3")

reject:
  case kind
  of {k1, k2, k3}, [k4]: discard KindObj(kind: kind, i32: 1)
  else: discard KindObj(kind: kind, str: "3")

accept:
  case kind
  of k3, k5: discard NestedKindObj(kind: kind)
  of k2: discard NestedKindObj(kind: kind, str: "not nested")
  of k1, k4:
    let otherKind = ok5
    case otherKind
    of ok1..ok3: discard NestedKindObj(kind: kind, otherKind: otherKind, i32: 3)
    of ok4: discard NestedKindObj(kind: kind, otherKind: otherKind, f32: 5.0)
    else: discard NestedKindObj(kind: kind, otherKind: otherKind,
                                nestedStr: "nested")

reject:
  case kind
  of k3, k5: discard NestedKindObj(kind: kind)
  of k2: discard NestedKindObj(kind: kind, str: "not nested")
  of k1, k4:
    let otherKind = ok5
    case otherKind
    of ok1..ok3: discard NestedKindObj(kind: kind, otherKind: otherKind, i32: 3)
    else: discard NestedKindObj(kind: kind, otherKind: otherKind,
                                nestedStr: "nested")

var varkind = k4

reject: # not immutable.
  case varkind
  of k1, k2, k3: discard KindObj(varkind: kind, i32: 1)
  of k4: discard KindObj(varkind: kind, f32: 2.0)
  else: discard KindObj(varkind: kind, str: "3")

accept:
  proc kindProc(kind: Kind): KindObj =
    case kind:
    of k1: result = KindObj(kind: kind, i32: 1)
    else: discard

reject:
  proc varKindProc(kind: var Kind): KindObj =
    case kind:
    of k1: result = KindObj(kind: kind, i32: 1)
    else: discard

type
  Kind3 = enum
    A, B, C, E

  OkRange = range[B..C]
  NotOkRange = range[B..E]

  CaseObject = object
    case kind: Kind3
    of B, C:
      field: int
    else: discard

accept:
  let rtDiscriminator: OkRange = B
  discard CaseObject(kind: rtDiscriminator, field: 1)

accept:
  let rtDiscriminator = B
  discard CaseObject(kind: OkRange(rtDiscriminator), field: 1)

accept:
  const rtDiscriminator: NotOkRange = B
  discard CaseObject(kind: rtDiscriminator, field: 1)

accept:
  discard CaseObject(kind: NotOkRange(B), field: 1)

reject:
  let rtDiscriminator: NotOkRange = B
  discard CaseObject(kind: rtDiscriminator, field: 1)

reject:
  let rtDiscriminator = B
  discard CaseObject(kind: NotOkRange(rtDiscriminator), field: 1)

reject:
  type Obj = object
    case x: int
    of 0 .. 1000:
      field: int
    else:
      discard

  let x: range[0..15] = 1
  let o = Obj(x: x, field: 1)
