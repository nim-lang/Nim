discard """
  errormsg: "possible values {k1, k3, k4} are in conflict with discriminator values for selected object branch 3"
  line: 17
"""

type
  Kind = enum k1, k2, k3, k4, k5
  KindObj = object
    case kind: Kind
    of k1, k2..k3: i32: int32
    of k4: f32: float32
    else: str: string

let kind = k3
case kind
of k2: discard KindObj(kind: kind, i32: 1)
else: discard KindObj(kind: kind, str: "3")
