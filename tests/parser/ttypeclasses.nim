type
    R = ref
    V = var
    D = distinct
    P = ptr
    T = type
    S = static
    OBJ = object
    TPL = tuple
    SEQ = seq

var i: int
var x: ref int
var y: distinct int
var z: ptr int
const C = @[1, 2, 3]

static:
  doAssert x is ref
  doAssert y is distinct
  doAssert z is ptr
  doAssert C is static
  doAssert C[1] is static[int]
  doAssert C[0] is static[SomeInteger]
  doAssert C isnot static[string]
  doAssert C is SEQ|OBJ
  doAssert C isnot OBJ|TPL
  doAssert int is int
  doAssert int is T
  doAssert int is SomeInteger
  doAssert seq[int] is type
  doAssert seq[int] is type[seq]
  doAssert seq[int] isnot type[seq[float]]
  doAssert i isnot type[int]
  doAssert type(i) is type[int]
  doAssert x isnot T
  doAssert y isnot S
  doAssert z isnot enum
  doAssert x isnot object
  doAssert y isnot tuple
  doAssert z isnot seq

  # XXX: These cases don't work properly at the moment:
  # doAssert type[int] isnot int
  # doAssert type(int) isnot int

