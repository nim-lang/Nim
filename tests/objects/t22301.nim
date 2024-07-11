discard """
  errormsg: "branch initialization with a runtime discriminator is not supported for a branch whose fields have default values."
"""

# bug #22301
type
  Enum = enum A, B
  Object = object
    case a: Enum
    of A:
      integer: int = 200
    of B:
      time: string

let x = A
let s = Object(a: x)
echo s