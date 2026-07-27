discard """
  action: "run"
"""

# Test: {.cast(uncheckedAssign).} must suppress FieldDiscriminantCheck
# when a yield inside the pragma block causes the closure-iterator
# transform to split the body.  The discriminant assignment lands in
# the post-yield state and must inherit the wrapper.

type
  MyKind = enum mkOne, mkTwo
  MyVariant = object
    case kind: MyKind
    of mkOne:
      x: int
    of mkTwo:
      y: float

iterator iterUncheckedYield(dest: var MyVariant): int {.closure.} =
  {.cast(uncheckedAssign).}:
    yield 1
    dest.kind = mkTwo

block:
  var v = MyVariant(kind: mkOne, x: 42)
  var count = 0
  for x in iterUncheckedYield(v):
    if count == 0:
      doAssert x == 1
      inc count
      # don't break — continue to advance past the yield,
      # which runs the discriminant assignment
    else:
      break
  doAssert v.kind == mkTwo

iterator iterNestedPragma(dest: var MyVariant): int {.closure.} =
  {.cast(uncheckedAssign).}:
    {.cast(gcsafe).}:
      yield 1
      dest.kind = mkTwo

block:
  var v = MyVariant(kind: mkOne, x: 42)
  var count = 0
  for x in iterNestedPragma(v):
    if count == 0:
      doAssert x == 1
      inc count
    else:
      break
  doAssert v.kind == mkTwo
