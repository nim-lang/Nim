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
  assert x is ref
  assert y is distinct
  assert z is ptr
  assert C is static
  assert C[1] is static[int]
  assert C[0] is static[SomeInteger]
  assert C isnot static[string]
  assert C is SEQ|OBJ
  assert C isnot OBJ|TPL
  assert int is int
  assert int is T
  assert int is SomeInteger
  assert seq[int] is type
  assert seq[int] is type[seq]
  assert seq[int] isnot type[seq[float]]
  assert i isnot type[int]
  assert type(i) is type[int]
  assert x isnot T
  assert y isnot S
  assert z isnot enum
  assert x isnot object
  assert y isnot tuple
  assert z isnot seq

