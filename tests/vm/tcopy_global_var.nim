discard """
  nimout: "static done"
"""

# bug #5269

proc assertEq[T](arg0, arg1: T): void =
  assert arg0 == arg1, $arg0 & " == " & $arg1

type
  MyType = object
    str: string
    a: int

block:
  var localValue = MyType(str: "Original strning, (OK)", a: 0)
  var valueCopy = localValue
  valueCopy.a = 123
  valueCopy.str = "Modified strning, (not OK when in localValue)"
  assertEq(localValue.str, "Original strning, (OK)")
  assertEq(localValue.a,   0)

static:
  var localValue = MyType(str: "Original strning, (OK)", a: 0)
  var valueCopy = localValue
  valueCopy.a = 123
  valueCopy.str = "Modified strning, (not OK when in localValue)"
  assertEq(localValue.str, "Original strning, (OK)")
  assertEq(localValue.a,   0)
  echo "static done"
