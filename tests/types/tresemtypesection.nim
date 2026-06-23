discard """
  output: '''
NONE
a
NONE
a
'''
"""

# issue #24887

macro foo(x: typed) =
  result = x

foo:
  type
    Flags64 = distinct uint64

  const NONE = Flags64(0'u64)
  const MAX: Flags64 = Flags64(uint64.high)

  proc `$`(x: Flags64): string =
    case x:
    of NONE:
      return "NONE"
    of MAX:
      return "MAX"
    else:
      return "UNKNOWN"

  let okay = Flags64(128'u64)

  echo $NONE
  type Foo = ref object
    x: int
  discard Foo(x: 123)
  type Enum = enum a, b, c
  echo a
  type Bar[T] = object
    x: T
  discard Bar[int](x: 123)
  discard Bar[string](x: "abc")

  type
    Generic1[T] = object
    Generic2[T] = ref int
    Generic3[T] = ref Generic1[T]
    Generic4[T] = Generic2[T]
    GenericInst1 = Generic1[int]
    GenericInst2 = Generic2[int]
    GenericInst3 = Generic3[int]
    GenericInst4 = Generic4[int]

  # regression test:
  template templ(): untyped =
    proc injected() {.inject.} = discard
    int

  type TestInject = templ()
  var x1: TestInject
  injected() # normally works

echo $NONE
echo a
var x2: TestInject
injected()

block: # issue #24898
  type V[W] = object
  template g(d: int) = discard d
  g((; type J = V[int]; 0))
