template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

type
  Kind = enum k1, k2, k3, k4, k5
  KindObj = object
    case kind: Kind
    of k1, k2..k3: i32: int32
    of k4: f32: float32
    else: str: string

  HoledKind = enum hk1 = 0, hk2 = 2, hk3 = 3, hk4 = 4, hk5 = 5
  HoledObj = object
    case kind: HoledKind
    of hk1, hk2..hk3: i32: int32
    of hk4: f32: float32
    else: str: string

  IntObj = object
    case kind: int32
    of low(int32) .. -1: bad: string
    of 0: neutral: string
    of 1 .. high(int32): good: string
    else: error: string # maybe a bug in semtypes coverage checking?

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

reject: # k4 conflicts with i32
  case kind
  of k1, k2, k3, k4: discard KindObj(kind: kind, i32: 1)
  else: discard KindObj(kind: kind, str: "3")

reject: # k4 is not caught, conflicts with str in the else branch
  case kind
  of k1, k2, k3: discard KindObj(kind: kind, i32: 1)
  else: discard KindObj(kind: kind, str: "3")

let holedKind = hk5

reject: # Only ordinals, no holed enums...
  case kind
  of hk1, hk2, hk3: discard KindObj(kind: holedKind, i32: 1)
  of hk4: discard KindObj(kind: holedKind, f32: 2.0)
  else: discard KindObj(kind: holedKind, str: "3")

let intKind = 29'i32

accept:
  case intKind
  of low(int32) .. -1: discard IntObj(kind: intKind, bad: "bad")
  of 0: discard IntObj(kind: intKind, neutral: "neutral")
  of 1 .. high(int32): discard IntObj(kind: intKind, good: "good")
  else: discard IntObj(kind: intKind, error: "error")

reject: # 0 leaks to else
  case intKind
  of low(int32) .. -1: discard IntObj(kind: intKind, bad: "bad")
  of 1 .. high(int32): discard IntObj(kind: intKind, good: "good")
  else: discard IntObj(kind: intKind, error: "error")

accept:
  case intKind
  of low(int32) .. -1: discard IntObj(kind: intKind, bad: "bad")
  of 0: discard IntObj(kind: intKind, neutral: "neutral")
  of 1 .. 9, 10, 11 .. high(int32): discard IntObj(kind: intKind, good: "good")
  else: discard IntObj(kind: intKind, error: "error")
