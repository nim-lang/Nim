func succ*[T: Ordinal](x: T, y = 1): T {.magic: "Succ".}
  ## Returns the ``y``-th successor (default: 1) of the value ``x``.
  ## ``T`` has to be an `ordinal type <#Ordinal>`_.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised
  ## or a compile time error occurs.
  ##
  ## .. code-block:: Nim
  ##   let x = 5
  ##   echo succ(5)    # => 6
  ##   echo succ(5, 3) # => 8

func pred*[T: Ordinal](x: T, y = 1): T {.magic: "Pred".}
  ## Returns the ``y``-th predecessor (default: 1) of the value ``x``.
  ## ``T`` has to be an `ordinal type <#Ordinal>`_.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised
  ## or a compile time error occurs.
  ##
  ## .. code-block:: Nim
  ##   let x = 5
  ##   echo pred(5)    # => 4
  ##   echo pred(5, 3) # => 2

proc inc*[T: Ordinal|uint|uint64](x: var T, y = 1) {.magic: "Inc", noSideEffect.}
  ## Increments the ordinal ``x`` by ``y``.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised or a compile
  ## time error occurs. This is a short notation for: ``x = succ(x, y)``.
  ##
  ## .. code-block:: Nim
  ##  var i = 2
  ##  inc(i)    # i <- 3
  ##  inc(i, 3) # i <- 6

proc dec*[T: Ordinal|uint|uint64](x: var T, y = 1) {.magic: "Dec", noSideEffect.}
  ## Decrements the ordinal ``x`` by ``y``.
  ##
  ## If such a value does not exist, ``OverflowError`` is raised or a compile
  ## time error occurs. This is a short notation for: ``x = pred(x, y)``.
  ##
  ## .. code-block:: Nim
  ##  var i = 2
  ##  dec(i)    # i <- 1
  ##  dec(i, 3) # i <- -2



# --------------------------------------------------------------------------
# built-in operators

when defined(nimNoZeroExtendMagic):
  proc ze*(x: int8): int {.deprecated.} =
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int](uint(cast[uint8](x)))

  proc ze*(x: int16): int {.deprecated.} =
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int](uint(cast[uint16](x)))

  proc ze64*(x: int8): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint8](x)))

  proc ze64*(x: int16): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint16](x)))

  proc ze64*(x: int32): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint32](x)))

  proc ze64*(x: int): int64 {.deprecated.} =
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned. Does nothing if the size of an ``int`` is the same as ``int64``.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint](x)))

  proc toU8*(x: int): int8 {.deprecated.} =
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int8](x)

  proc toU16*(x: int): int16 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an ``int16`` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int16](x)

  proc toU32*(x: int64): int32 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an ``int32`` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int32](x)

elif not defined(js):
  proc ze*(x: int8): int {.magic: "Ze8ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze*(x: int16): int {.magic: "Ze16ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int8): int64 {.magic: "Ze8ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int16): int64 {.magic: "Ze16ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int32): int64 {.magic: "Ze32ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int): int64 {.magic: "ZeIToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to ``int64``. This treats `x` as
    ## unsigned. Does nothing if the size of an ``int`` is the same as ``int64``.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU8*(x: int): int8 {.magic: "ToU8", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU16*(x: int): int16 {.magic: "ToU16", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an ``int16`` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU32*(x: int64): int32 {.magic: "ToU32", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an ``int32`` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

# integer calculations:
func `+`*(x: int): int {.magic: "UnaryPlusI".}
  ## Unary `+` operator for an integer. Has no effect.
func `+`*(x: int8): int8 {.magic: "UnaryPlusI".}
func `+`*(x: int16): int16 {.magic: "UnaryPlusI".}
func `+`*(x: int32): int32 {.magic: "UnaryPlusI".}
func `+`*(x: int64): int64 {.magic: "UnaryPlusI".}

func `-`*(x: int): int {.magic: "UnaryMinusI".}
  ## Unary `-` operator for an integer. Negates `x`.
func `-`*(x: int8): int8 {.magic: "UnaryMinusI".}
func `-`*(x: int16): int16 {.magic: "UnaryMinusI".}
func `-`*(x: int32): int32 {.magic: "UnaryMinusI".}
func `-`*(x: int64): int64 {.magic: "UnaryMinusI64".}

func `not`*(x: int): int {.magic: "BitnotI".}
  ## Computes the `bitwise complement` of the integer `x`.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = 0'u8
  ##     b = 0'i8
  ##     c = 1000'u16
  ##     d = 1000'i16
  ##
  ##   echo not a # => 255
  ##   echo not b # => -1
  ##   echo not c # => 64535
  ##   echo not d # => -1001
func `not`*(x: int8): int8 {.magic: "BitnotI".}
func `not`*(x: int16): int16 {.magic: "BitnotI".}
func `not`*(x: int32): int32 {.magic: "BitnotI".}
func `not`*(x: int64): int64 {.magic: "BitnotI".}

func `+`*(x, y: int): int {.magic: "AddI".}
  ## Binary `+` operator for an integer.
func `+`*(x, y: int8): int8 {.magic: "AddI".}
func `+`*(x, y: int16): int16 {.magic: "AddI".}
func `+`*(x, y: int32): int32 {.magic: "AddI".}
func `+`*(x, y: int64): int64 {.magic: "AddI".}

func `-`*(x, y: int): int {.magic: "SubI".}
  ## Binary `-` operator for an integer.
func `-`*(x, y: int8): int8 {.magic: "SubI".}
func `-`*(x, y: int16): int16 {.magic: "SubI".}
func `-`*(x, y: int32): int32 {.magic: "SubI".}
func `-`*(x, y: int64): int64 {.magic: "SubI".}

func `*`*(x, y: int): int {.magic: "MulI".}
  ## Binary `*` operator for an integer.
func `*`*(x, y: int8): int8 {.magic: "MulI".}
func `*`*(x, y: int16): int16 {.magic: "MulI".}
func `*`*(x, y: int32): int32 {.magic: "MulI".}
func `*`*(x, y: int64): int64 {.magic: "MulI".}

func `div`*(x, y: int): int {.magic: "DivI".}
  ## Computes the integer division.
  ##
  ## This is roughly the same as ``trunc(x/y)``.
  ##
  ## .. code-block:: Nim
  ##   ( 1 div  2) ==  0
  ##   ( 2 div  2) ==  1
  ##   ( 3 div  2) ==  1
  ##   ( 7 div  3) ==  2
  ##   (-7 div  3) == -2
  ##   ( 7 div -3) == -2
  ##   (-7 div -3) ==  2
func `div`*(x, y: int8): int8 {.magic: "DivI".}
func `div`*(x, y: int16): int16 {.magic: "DivI".}
func `div`*(x, y: int32): int32 {.magic: "DivI".}
func `div`*(x, y: int64): int64 {.magic: "DivI".}

func `mod`*(x, y: int): int {.magic: "ModI".}
  ## Computes the integer modulo operation (remainder).
  ##
  ## This is the same as ``x - (x div y) * y``.
  ##
  ## .. code-block:: Nim
  ##   ( 7 mod  5) ==  2
  ##   (-7 mod  5) == -2
  ##   ( 7 mod -5) ==  2
  ##   (-7 mod -5) == -2
func `mod`*(x, y: int8): int8 {.magic: "ModI".}
func `mod`*(x, y: int16): int16 {.magic: "ModI".}
func `mod`*(x, y: int32): int32 {.magic: "ModI".}
func `mod`*(x, y: int64): int64 {.magic: "ModI".}

when defined(nimOldShiftRight) or not defined(nimAshr):
  const shrDepMessage = "`shr` will become sign preserving."
  proc `shr`*(x: int, y: SomeInteger): int {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int8, y: SomeInteger): int8 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int16, y: SomeInteger): int16 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int32, y: SomeInteger): int32 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
  proc `shr`*(x: int64, y: SomeInteger): int64 {.magic: "ShrI", noSideEffect, deprecated: shrDepMessage.}
else:
  func `shr`*(x: int, y: SomeInteger): int {.magic: "AshrI".}
    ## Computes the `shift right` operation of `x` and `y`, filling
    ## vacant bit positions with the sign bit.
    ##
    ## **Note**: `Operator precedence <manual.html#syntax-precedence>`_
    ## is different than in *C*.
    ##
    ## See also:
    ## * `ashr func <#ashr,int,SomeInteger>`_ for arithmetic shift right
    ##
    ## .. code-block:: Nim
    ##   0b0001_0000'i8 shr 2 == 0b0000_0100'i8
    ##   0b0000_0001'i8 shr 1 == 0b0000_0000'i8
    ##   0b1000_0000'i8 shr 4 == 0b1111_1000'i8
    ##   -1 shr 5 == -1
    ##   1 shr 5 == 0
    ##   16 shr 2 == 4
    ##   -16 shr 2 == -4
  func `shr`*(x: int8, y: SomeInteger): int8 {.magic: "AshrI".}
  func `shr`*(x: int16, y: SomeInteger): int16 {.magic: "AshrI".}
  func `shr`*(x: int32, y: SomeInteger): int32 {.magic: "AshrI".}
  func `shr`*(x: int64, y: SomeInteger): int64 {.magic: "AshrI".}


func `shl`*(x: int, y: SomeInteger): int {.magic: "ShlI".}
  ## Computes the `shift left` operation of `x` and `y`.
  ##
  ## **Note**: `Operator precedence <manual.html#syntax-precedence>`_
  ## is different than in *C*.
  ##
  ## .. code-block:: Nim
  ##  1'i32 shl 4 == 0x0000_0010
  ##  1'i64 shl 4 == 0x0000_0000_0000_0010
func `shl`*(x: int8, y: SomeInteger): int8 {.magic: "ShlI".}
func `shl`*(x: int16, y: SomeInteger): int16 {.magic: "ShlI".}
func `shl`*(x: int32, y: SomeInteger): int32 {.magic: "ShlI".}
func `shl`*(x: int64, y: SomeInteger): int64 {.magic: "ShlI".}

when defined(nimAshr):
  func ashr*(x: int, y: SomeInteger): int {.magic: "AshrI".}
    ## Shifts right by pushing copies of the leftmost bit in from the left,
    ## and let the rightmost bits fall off.
    ##
    ## Note that `ashr` is not an operator so use the normal function
    ## call syntax for it.
    ##
    ## See also:
    ## * `shr func <#shr,int,SomeInteger>`_
    ##
    ## .. code-block:: Nim
    ##   ashr(0b0001_0000'i8, 2) == 0b0000_0100'i8
    ##   ashr(0b1000_0000'i8, 8) == 0b1111_1111'i8
    ##   ashr(0b1000_0000'i8, 1) == 0b1100_0000'i8
  func ashr*(x: int8, y: SomeInteger): int8 {.magic: "AshrI".}
  func ashr*(x: int16, y: SomeInteger): int16 {.magic: "AshrI".}
  func ashr*(x: int32, y: SomeInteger): int32 {.magic: "AshrI".}
  func ashr*(x: int64, y: SomeInteger): int64 {.magic: "AshrI".}
else:
  # used for bootstrapping the compiler
  proc ashr*[T](x: T, y: SomeInteger): T = discard

func `and`*(x, y: int): int {.magic: "BitandI".}
  ## Computes the `bitwise and` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 and 0b0101) == 0b0001
  ##   (0b0111 and 0b1100) == 0b0100
func `and`*(x, y: int8): int8 {.magic: "BitandI".}
func `and`*(x, y: int16): int16 {.magic: "BitandI".}
func `and`*(x, y: int32): int32 {.magic: "BitandI".}
func `and`*(x, y: int64): int64 {.magic: "BitandI".}

func `or`*(x, y: int): int {.magic: "BitorI".}
  ## Computes the `bitwise or` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 or 0b0101) == 0b0111
  ##   (0b0111 or 0b1100) == 0b1111
func `or`*(x, y: int8): int8 {.magic: "BitorI".}
func `or`*(x, y: int16): int16 {.magic: "BitorI".}
func `or`*(x, y: int32): int32 {.magic: "BitorI".}
func `or`*(x, y: int64): int64 {.magic: "BitorI".}

func `xor`*(x, y: int): int {.magic: "BitxorI".}
  ## Computes the `bitwise xor` of numbers `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   (0b0011 xor 0b0101) == 0b0110
  ##   (0b0111 xor 0b1100) == 0b1011
func `xor`*(x, y: int8): int8 {.magic: "BitxorI".}
func `xor`*(x, y: int16): int16 {.magic: "BitxorI".}
func `xor`*(x, y: int32): int32 {.magic: "BitxorI".}
func `xor`*(x, y: int64): int64 {.magic: "BitxorI".}

type
  IntMax32 = int|int8|int16|int32

func `+%`*(x, y: IntMax32): IntMax32 {.magic: "AddU".}
func `+%`*(x, y: int64): int64 {.magic: "AddU".}
  ## Treats `x` and `y` as unsigned and adds them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

func `-%`*(x, y: IntMax32): IntMax32 {.magic: "SubU".}
func `-%`*(x, y: int64): int64 {.magic: "SubU".}
  ## Treats `x` and `y` as unsigned and subtracts them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

func `*%`*(x, y: IntMax32): IntMax32 {.magic: "MulU".}
func `*%`*(x, y: int64): int64 {.magic: "MulU".}
  ## Treats `x` and `y` as unsigned and multiplies them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

func `/%`*(x, y: IntMax32): IntMax32 {.magic: "DivU".}
func `/%`*(x, y: int64): int64 {.magic: "DivU".}
  ## Treats `x` and `y` as unsigned and divides them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.

func `%%`*(x, y: IntMax32): IntMax32 {.magic: "ModU".}
func `%%`*(x, y: int64): int64 {.magic: "ModU".}
  ## Treats `x` and `y` as unsigned and compute the modulo of `x` and `y`.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.


# unsigned integer operations:
func `not`*(x: uint): uint {.magic: "BitnotI".}
  ## Computes the `bitwise complement` of the integer `x`.
func `not`*(x: uint8): uint8 {.magic: "BitnotI".}
func `not`*(x: uint16): uint16 {.magic: "BitnotI".}
func `not`*(x: uint32): uint32 {.magic: "BitnotI".}
func `not`*(x: uint64): uint64 {.magic: "BitnotI".}

func `shr`*(x: uint, y: SomeInteger): uint {.magic: "ShrI".}
  ## Computes the `shift right` operation of `x` and `y`.
func `shr`*(x: uint8, y: SomeInteger): uint8 {.magic: "ShrI".}
func `shr`*(x: uint16, y: SomeInteger): uint16 {.magic: "ShrI".}
func `shr`*(x: uint32, y: SomeInteger): uint32 {.magic: "ShrI".}
func `shr`*(x: uint64, y: SomeInteger): uint64 {.magic: "ShrI".}

func `shl`*(x: uint, y: SomeInteger): uint {.magic: "ShlI".}
  ## Computes the `shift left` operation of `x` and `y`.
func `shl`*(x: uint8, y: SomeInteger): uint8 {.magic: "ShlI".}
func `shl`*(x: uint16, y: SomeInteger): uint16 {.magic: "ShlI".}
func `shl`*(x: uint32, y: SomeInteger): uint32 {.magic: "ShlI".}
func `shl`*(x: uint64, y: SomeInteger): uint64 {.magic: "ShlI".}

func `and`*(x, y: uint): uint {.magic: "BitandI".}
  ## Computes the `bitwise and` of numbers `x` and `y`.
func `and`*(x, y: uint8): uint8 {.magic: "BitandI".}
func `and`*(x, y: uint16): uint16 {.magic: "BitandI".}
func `and`*(x, y: uint32): uint32 {.magic: "BitandI".}
func `and`*(x, y: uint64): uint64 {.magic: "BitandI".}

func `or`*(x, y: uint): uint {.magic: "BitorI".}
  ## Computes the `bitwise or` of numbers `x` and `y`.
func `or`*(x, y: uint8): uint8 {.magic: "BitorI".}
func `or`*(x, y: uint16): uint16 {.magic: "BitorI".}
func `or`*(x, y: uint32): uint32 {.magic: "BitorI".}
func `or`*(x, y: uint64): uint64 {.magic: "BitorI".}

func `xor`*(x, y: uint): uint {.magic: "BitxorI".}
  ## Computes the `bitwise xor` of numbers `x` and `y`.
func `xor`*(x, y: uint8): uint8 {.magic: "BitxorI".}
func `xor`*(x, y: uint16): uint16 {.magic: "BitxorI".}
func `xor`*(x, y: uint32): uint32 {.magic: "BitxorI".}
func `xor`*(x, y: uint64): uint64 {.magic: "BitxorI".}

func `+`*(x, y: uint): uint {.magic: "AddU".}
  ## Binary `+` operator for unsigned integers.
func `+`*(x, y: uint8): uint8 {.magic: "AddU".}
func `+`*(x, y: uint16): uint16 {.magic: "AddU".}
func `+`*(x, y: uint32): uint32 {.magic: "AddU".}
func `+`*(x, y: uint64): uint64 {.magic: "AddU".}

func `-`*(x, y: uint): uint {.magic: "SubU".}
  ## Binary `-` operator for unsigned integers.
func `-`*(x, y: uint8): uint8 {.magic: "SubU".}
func `-`*(x, y: uint16): uint16 {.magic: "SubU".}
func `-`*(x, y: uint32): uint32 {.magic: "SubU".}
func `-`*(x, y: uint64): uint64 {.magic: "SubU".}

func `*`*(x, y: uint): uint {.magic: "MulU".}
  ## Binary `*` operator for unsigned integers.
func `*`*(x, y: uint8): uint8 {.magic: "MulU".}
func `*`*(x, y: uint16): uint16 {.magic: "MulU".}
func `*`*(x, y: uint32): uint32 {.magic: "MulU".}
func `*`*(x, y: uint64): uint64 {.magic: "MulU".}

func `div`*(x, y: uint): uint {.magic: "DivU".}
  ## Computes the integer division for unsigned integers.
  ## This is roughly the same as ``trunc(x/y)``.
func `div`*(x, y: uint8): uint8 {.magic: "DivU".}
func `div`*(x, y: uint16): uint16 {.magic: "DivU".}
func `div`*(x, y: uint32): uint32 {.magic: "DivU".}
func `div`*(x, y: uint64): uint64 {.magic: "DivU".}

func `mod`*(x, y: uint): uint {.magic: "ModU".}
  ## Computes the integer modulo operation (remainder) for unsigned integers.
  ## This is the same as ``x - (x div y) * y``.
func `mod`*(x, y: uint8): uint8 {.magic: "ModU".}
func `mod`*(x, y: uint16): uint16 {.magic: "ModU".}
func `mod`*(x, y: uint32): uint32 {.magic: "ModU".}
func `mod`*(x, y: uint64): uint64 {.magic: "ModU".}




func `+=`*[T: SomeInteger](x: var T, y: T) {.magic: "Inc".}
  ## Increments an integer.

func `+=`*[T: enum|bool](x: var T, y: T) {.
  magic: "Inc", deprecated: "use `inc` instead".}
  ## **Deprecated since v0.20**: use `inc` instead.

func `-=`*[T: SomeInteger](x: var T, y: T) {.magic: "Dec".}
  ## Decrements an integer.

func `-=`*[T: enum|bool](x: var T, y: T) {.
  magic: "Dec", deprecated: "0.20.0, use `dec` instead".}
  ## **Deprecated since v0.20**: use `dec` instead.

func `*=`*[T: SomeInteger](x: var T, y: T) {.
  inline.} =
  ## Binary `*=` operator for integers.
  x = x * y
