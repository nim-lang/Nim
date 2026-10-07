discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
tsumtype_fieldless_construct: OK
'''
"""

# ported from Nimony's tests/nimony/object/tsumtype_fieldless_construct.nim


# Regression: constructing a fieldless sum-type branch (`of None: discard`)
# through a generic proc's `result` slot used to hang the compiler — typeOfField
# in typenav.nim spun forever on the empty branch body during the deref pass,
# because the non-field node was navigated without advancing the cursor. With a
# phantom pad field the branch held a real Fld and advanced, which is why only
# the truly fieldless case stalled.

type
  Opt[T] = object
    case
    of None:
      discard
    of Some:
      val: T

proc none[T](): Opt[T] = result = None()
proc some[T](v: T): Opt[T] = Some(val: v)

proc isSome[T](o: Opt[T]): bool =
  case o
  of Some(_): result = true
  of None(): result = false

# fieldless branch via a generic proc's result slot (the case that hung):
let a = none[int]()
assert not a.isSome

# the value branch still works alongside the fieldless one:
let b = some(42)
assert b.isSome
{.cast(uncheckedAccess).}:
  assert b.val == 42

echo "tsumtype_fieldless_construct: OK"
