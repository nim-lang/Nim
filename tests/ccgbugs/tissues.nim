discard """
action: compile
"""

# bug #2233
type MalType = object
  fun: proc: MalType

proc f(x: proc: MalType) =
  discard x()

f(nil)

# bug #2823

type A = object #of RootObj <-- Uncomment this to get no errors
  test: proc(i: A): bool
var a: proc(i: A): bool # Or comment this line to get no errors


# bug #2703
type
  fooObj[T] = object of RootObj
  bazObj[T] = object of fooObj[T]
    x: T

var troz: fooObj[string]
echo bazObj[string](troz).x


# bug #14880
type step = object
  exec: proc ()

const pipeline = @[step()]

let crash = pipeline[0]

