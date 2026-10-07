discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
42 3
(x: 1.0, y: 2.0, `kind: Circle, radius: 5.0, color: 255)
(x: 0.0, y: 0.0, `kind: Rect, w: 2.0, h: 3.0, color: 0)
(`kind: Some, val: 42) (`kind: None)
(`kind: Some, val: "hello") Opt[system.string]
Tree[system.int] 7 8
(`kind: Some, val: 10) (`kind: None)
(`kind: None) (`kind: Another)
(`kind: Some, val: 1) (`kind: Some, val: (`kind: Some, val: 2)) @[(`kind: Some, val: 'c'), (`kind: None)]
(`kind: Lit, v: 2.5)
(`kind: Some, val: 12)
(`kind: Some, val: 4) 42
(`kind: Some, val: 3) (`kind: Some, val: "x") (`kind: None)
false true
'''
"""

{.experimental: "sumTypes".}

import msumtypes as m

type
  Node = ref object
    case
    of AddOpr, SubOpr:
      a, b: Node
    of Value:
      val: int
  Shape = object
    x, y: float
    case
    of Circle: radius: float
    of Rect: w, h: float
    color: int
  Tree[T] = ref object
    case
    of Leaf: v: T
    of Fork: l, r: Tree[T]
  Other = object
    case
    of None: discard   # also a branch of `m.Opt`
    of Another: discard
  Addable = concept
    proc `+`(a, b: Self): Self
  Expr[T: Addable] = object
    case
    of Lit: v: T
    of Neg: discard

# named arguments, shared fields in any order:
let v = Value(val: 42)
let add = AddOpr(a: Value(val: 1), b: Value(val: 2))
echo v.val, " ", add.a.val + add.b.val
echo Circle(x: 1.0, y: 2.0, color: 0xFF, radius: 5.0)
echo Rect(w: 2.0, h: 3.0)

# the expected type selects the sum type and its generic instance:
let a: Opt[int] = Some(val: 42)
let n: Opt[float] = None()
echo a, " ", n

# without an expected type, the generic parameters are inferred from the
# field values; for a `ref object` the result is the `ref` type:
let b = Some(val: "hello")
echo b, " ", typeof(b)
let t = Leaf(v: 7)
let f = Fork(l: t, r: Leaf(v: 8))
echo typeof(t), " ", t.v, " ", f.r.v

# a type conversion works like an expected type:
echo Opt[int](Some(val: 10)), " ", Opt[string](None())
echo Other(None()), " ", Another()

# in templates and generic routines:
template mk(x): untyped = Some(val: x)
proc wrap[T](x: T): Opt[Opt[T]] = Some(val: Some(val: x))
proc lits[T](x: T): seq[Opt[T]] = @[Some(val: x), None()]
echo mk(1), " ", wrap(2), " ", lits('c')

# a concept constraint:
echo Lit(v: 2.5)

# at compile time:
const c = Some(val: 12)
static: doAssert c.val == 12
echo c

# field values that declare symbols are fine:
let q = Some(val: (var tmp = 3; inc tmp; tmp))
let r = Some(val: proc (x: int): int = x * 2)
echo q, " ", r.val(21)

# across modules:
let x: Opt[int] = none[int]()
echo some(3), " ", some("x"), " ", x
echo compiles(H1(secret: 1)), " ", compiles(H2())
