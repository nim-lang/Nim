type
  int* {.magic: "Int".}         ## Default integer type; bitwidth depends on
                              ## architecture, but is always the same as a pointer.
  int8* {.magic: "Int8".}       ## Signed 8 bit integer type.
  int16* {.magic: "Int16".}     ## Signed 16 bit integer type.
  int32* {.magic: "Int32".}     ## Signed 32 bit integer type.
  int64* {.magic: "Int64".}     ## Signed 64 bit integer type.
  uint* {.magic: "UInt".}       ## Unsigned default integer type.
  uint8* {.magic: "UInt8".}     ## Unsigned 8 bit integer type.
  uint16* {.magic: "UInt16".}   ## Unsigned 16 bit integer type.
  uint32* {.magic: "UInt32".}   ## Unsigned 32 bit integer type.
  uint64* {.magic: "UInt64".}   ## Unsigned 64 bit integer type.

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

  SomeOrdinal* = int|int8|int16|int32|int64|bool|enum|uint|uint8|uint16|uint32|uint64
    ## Type class matching all ordinal types; however this includes enums with
    ## holes. See also `Ordinal`

  BiggestInt* = int64
    ## is an alias for the biggest signed integer type the Nim compiler
    ## supports. Currently this is `int64`, but it is platform-dependent
    ## in general.


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
