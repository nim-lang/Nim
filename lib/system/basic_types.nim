type
  int* {.magic: Int.}         ## Default integer type; bitwidth depends on
                              ## architecture, but is always the same as a pointer.
  int8* {.magic: Int8.}       ## Signed 8 bit integer type.
  int16* {.magic: Int16.}     ## Signed 16 bit integer type.
  int32* {.magic: Int32.}     ## Signed 32 bit integer type.
  int64* {.magic: Int64.}     ## Signed 64 bit integer type.
  uint* {.magic: UInt.}       ## Unsigned default integer type.
  uint8* {.magic: UInt8.}     ## Unsigned 8 bit integer type.
  uint16* {.magic: UInt16.}   ## Unsigned 16 bit integer type.
  uint32* {.magic: UInt32.}   ## Unsigned 32 bit integer type.
  uint64* {.magic: UInt64.}   ## Unsigned 64 bit integer type.

type
  float* {.magic: Float.}     ## Default floating point type.
  float32* {.magic: Float32.} ## 32 bit floating point type.
  float64* {.magic: Float.}   ## 64 bit floating point type.

# 'float64' is now an alias to 'float'; this solves many problems

type
  char* {.magic: Char.}         ## Built-in 8 bit character type (unsigned).
  string* {.magic: String.}     ## Built-in string type.
  cstring* {.magic: Cstring.}   ## Built-in cstring (*compatible string*) type.
  pointer* {.magic: Pointer.}   ## Built-in pointer type, use the `addr`
                                ## operator to get a pointer to a variable.

  typedesc* {.magic: TypeDesc.} ## Meta type to denote a type description.

type
  `ptr`*[T] {.magic: Pointer.}   ## Built-in generic untraced pointer type.
  `ref`*[T] {.magic: Pointer.}   ## Built-in generic traced pointer type.

  `nil` {.magic: "Nil".}

  void* {.magic: "VoidType".}    ## Meta type to denote the absence of any type.
  auto* {.magic: Expr.}          ## Meta type for automatic type determination.
  any* {.deprecated: "Deprecated since v1.5; Use auto instead.".} = distinct auto  ## Deprecated; Use `auto` instead. See https://github.com/nim-lang/RFCs/issues/281
  untyped* {.magic: Expr.}       ## Meta type to denote an expression that
                                 ## is not resolved (for templates).
  typed* {.magic: Stmt.}         ## Meta type to denote an expression that
                                 ## is resolved (for templates).

type # we need to start a new type section here, so that ``0`` can have a type
  bool* {.magic: "Bool".} = enum ## Built-in boolean type.
    false = 0, true = 1

const
  on* = true    ## Alias for `true`.
  off* = false  ## Alias for `false`.

type
  SomeSignedInt* = int|int8|int16|int32|int64
    ## Type class matching all signed integer types.

  SomeUnsignedInt* = uint|uint8|uint16|uint32|uint64
    ## Type class matching all unsigned integer types.

  SomeInteger* = SomeSignedInt|SomeUnsignedInt
    ## Type class matching all integer types.

  SomeFloat* = float|float32|float64
    ## Type class matching all floating point number types.

  SomeNumber* = SomeInteger|SomeFloat
    ## Type class matching all number types.

  SomeOrdinal* = int|int8|int16|int32|int64|bool|enum|uint|uint8|uint16|uint32|uint64
    ## Type class matching all ordinal types; however this includes enums with
    ## holes. See also `Ordinal`


{.push warning[GcMem]: off, warning[Uninit]: off.}
{.push hints: off.}

proc `not`*(x: bool): bool {.magic: "Not", noSideEffect.}
  ## Boolean not; returns true if `x == false`.

proc `and`*(x, y: bool): bool {.magic: "And", noSideEffect.}
  ## Boolean `and`; returns true if `x == y == true` (if both arguments
  ## are true).
  ##
  ## Evaluation is lazy: if `x` is false, `y` will not even be evaluated.
proc `or`*(x, y: bool): bool {.magic: "Or", noSideEffect.}
  ## Boolean `or`; returns true if `not (not x and not y)` (if any of
  ## the arguments is true).
  ##
  ## Evaluation is lazy: if `x` is true, `y` will not even be evaluated.
proc `xor`*(x, y: bool): bool {.magic: "Xor", noSideEffect.}
  ## Boolean `exclusive or`; returns true if `x != y` (if either argument
  ## is true while the other is false).

{.pop.}
{.pop.}
