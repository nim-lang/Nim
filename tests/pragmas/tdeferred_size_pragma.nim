discard """
  targets: "c cpp"
"""
## Test: Deferred `size` pragma with generic type parameters
##
## Coverage:
## - Single generic param: sizeof(T)
## - Multiple generic params: sizeof(A), sizeof(B), sizeof(A)+sizeof(B)
## - Complex expressions: sizeof(T)+N, sizeof(T)*N
## - C++ templates (cpp backend only)
##
## Note: The `size` pragma is ONLY valid on:
## - Enum types
## - Imported types (types with {.importc.} or {.importcpp.})
## It is NOT valid on fields or variables.

# -----------------------------------------------------------------------------
# Single generic parameter
# -----------------------------------------------------------------------------

type Single[T] {.importc, size: sizeof(T), completeStruct.} = object

static:
  doAssert sizeof(Single[int8]) == 1
  doAssert sizeof(Single[int16]) == 2
  doAssert sizeof(Single[int32]) == 4
  doAssert sizeof(Single[int64]) == 8

  # Prove different instantiations have different sizes (feature actually works):
  doAssert sizeof(Single[int8]) != sizeof(Single[int64])
  doAssert sizeof(Single[int16]) != sizeof(Single[int32])

  # Prove size comes from pragma expression, not natural size:
  # If pragma were broken, compiler would use natural object size (1 byte on most archs)
  doAssert sizeof(Single[int64]) == 8  # Would be 1 if pragma didn't work

# -----------------------------------------------------------------------------
# Multiple generic parameters
# -----------------------------------------------------------------------------

type FirstParam[A, B] {.importc, size: sizeof(A), completeStruct.} = object

static:
  doAssert sizeof(FirstParam[int8, int64]) == 1
  doAssert sizeof(FirstParam[int64, int8]) == 8

type SecondParam[A, B] {.importc, size: sizeof(B), completeStruct.} = object

static:
  doAssert sizeof(SecondParam[int8, int64]) == 8
  doAssert sizeof(SecondParam[int64, int8]) == 1

type BothParams[A, B] {.importc, size: sizeof(A) + sizeof(B), completeStruct.} = object

static:
  doAssert sizeof(BothParams[int8, int8]) == 2
  doAssert sizeof(BothParams[int32, int64]) == 12

  # Verify expression uses BOTH params (would fail if only one was used):
  doAssert sizeof(BothParams[int8, int64]) == 9   # 1 + 8
  doAssert sizeof(BothParams[int64, int8]) == 9   # 8 + 1
  doAssert sizeof(BothParams[int32, int32]) == 8  # 4 + 4

# -----------------------------------------------------------------------------
# Complex expressions
# -----------------------------------------------------------------------------

type PlusConst[T] {.importc, size: sizeof(T) + 4, completeStruct.} = object

static:
  doAssert sizeof(PlusConst[int8]) == 5
  doAssert sizeof(PlusConst[int32]) == 8

type TimesConst[T] {.importc, size: sizeof(T) * 2, completeStruct.} = object

static:
  doAssert sizeof(TimesConst[int8]) == 2
  doAssert sizeof(TimesConst[int32]) == 8

type ComplexExpr[T] {.importc, size: sizeof(T) * 2 + 4, completeStruct.} = object

static:
  doAssert sizeof(ComplexExpr[int8]) == 6
  doAssert sizeof(ComplexExpr[int32]) == 12

# -----------------------------------------------------------------------------
# Non-generic (regression test: ensure fixed sizes still work)
# -----------------------------------------------------------------------------

type FixedSize {.importc, size: 16, completeStruct.} = object

static:
  doAssert sizeof(FixedSize) == 16

# -----------------------------------------------------------------------------
# Edge case: size expression with multiple operations
# -----------------------------------------------------------------------------

type MultiOpSize[T] {.importc, size: (sizeof(T) * 3 + 7) div 8 * 8, completeStruct.} = object

static:
  # Rounds up to nearest multiple of 8
  doAssert sizeof(MultiOpSize[int8]) == 8   # (1*3+7)/8*8 = 8
  doAssert sizeof(MultiOpSize[int16]) == 8  # (2*3+7)/8*8 = 8
  doAssert sizeof(MultiOpSize[int32]) == 16 # (4*3+7)/8*8 = 16

# -----------------------------------------------------------------------------
# C++ templates
# -----------------------------------------------------------------------------

when defined(cpp):
  type CppAtomic[T] {.importcpp: "std::atomic", header: "<atomic>",
                      size: sizeof(T), completeStruct.} = object

  static:
    doAssert sizeof(CppAtomic[int8]) == 1
    doAssert sizeof(CppAtomic[int32]) == 4
    doAssert sizeof(CppAtomic[int64]) == 8
