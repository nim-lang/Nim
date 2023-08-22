discard """
disabled: "arm64"
"""

# bug #11792
type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

  MyKind = enum
    k1, k2, k3

  MyTypeObj = object
    kind: MyKind
    x: int
    amount: UncheckedArray[m256d]


# The sizeof(MyTypeObj) is not equal to (sizeof(int) + sizeof(MyKind)) due to
# alignment requirement of m256d, make sure Nim understands that
doAssert(sizeof(MyTypeObj) > sizeof(int) + sizeof(MyKind))
