discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
tsumtype: OK
'''
"""

# ported from Nimony's tests/nimony/object/tsumtype.nim


type
  Node = ref object
    case
    of AddOpr, SubOpr:
      a, b: Node
    of Value:
      val: int

let v: Node = Value(val: 42)
{.cast(uncheckedAccess).}:
  assert v.val == 42

let v2 = Value(val: 42)
{.cast(uncheckedAccess).}:
  assert v2.val == 42

let add: Node = AddOpr(a: v, b: Value(val: 10))
{.cast(uncheckedAccess).}:
  assert add.a.val == 42
  assert add.b.val == 10

proc eval(n: Node): int =
  case n
  of Value(val):
    result = val
  of AddOpr(a, b):
    result = eval(a) + eval(b)
  of SubOpr(a, b):
    result = eval(a) - eval(b)

assert eval(v) == 42
assert eval(add) == 52

let sub: Node = SubOpr(a: Value(val: 100), b: Value(val: 30))
assert eval(sub) == 70

let nested: Node = AddOpr(
  a: SubOpr(a: Value(val: 50), b: Value(val: 20)),
  b: Value(val: 5)
)
assert eval(nested) == 35

proc depth(n: Node): int =
  case n
  of Value(val):
    result = 0
  of {AddOpr, SubOpr}(a, b):
    let da = depth(a)
    let db = depth(b)
    if da > db:
      result = da + 1
    else:
      result = db + 1

assert depth(v) == 0
assert depth(add) == 1
assert depth(nested) == 2

# A constructor used directly as an argument has no expected type to guide it
# (#2480). The branch belongs to `Node`, which is a `ref object`, so the
# constructor must produce the `ref` -- not the split-off `Node.Obj`:
assert eval(AddOpr(a: Value(val: 10), b: Value(val: 32))) == 42
assert eval(v2) == 42
assert depth(SubOpr(a: Value(val: 1), b: AddOpr(a: v, b: v))) == 2

# A ref sum type declared in a proc body: there the split into `L`/`L.Obj` and
# the semcheck of the object body happen in one go, not one phase apart.
proc localSumType(): int =
  type
    L = ref object
      case
      of Nil:
        discard
      of Cons:
        head: int
        tail: L

  proc total(n: L): int =
    case n
    of Nil():
      result = 0
    of Cons(head, tail):
      result = head + total(tail)

  result = total(Cons(head: 1, tail: Cons(head: 2, tail: Nil())))

assert localSumType() == 3

echo "tsumtype: OK"
