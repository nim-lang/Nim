import
  unittest, macros

var
    a = 1
    b = 22
    c = 1
    d = 3

suite "my suite":
  setup:
    echo "suite setup"
    var testVar = "from setup"

  teardown:
    echo "suite teardown"

  test "first suite test":
    testVar = "modified"
    echo "test var: " & testVar
    check a > b

  test "second suite test":
    echo "test var: " & testVar

proc foo: bool =
  echo "running foo"
  return true

proc err =
  raise newException(EArithmetic, "some exception")

test "final test":
  echo "inside suite-less test"

  check:
    a == c
    foo()
    d > 10

test "arithmetic failure":
  expect(EArithmetic):
    err()

  expect(EArithmetic, ESystem):
    discard foo()

