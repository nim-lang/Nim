type
  BiggestInt* = int64
    ## is an alias for the biggest signed integer type the Nim compiler
    ## supports. Currently this is `int64`, but it is platform-dependent
    ## in general.

  BiggestFloat* = float64
    ## is an alias for the biggest floating point type the Nim
    ## compiler supports. Currently this is `float64`, but it is
    ## platform-dependent in general.

when defined(js):
  type BiggestUInt* = uint32
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is `uint32` for JS and `uint64` for other
    ## targets.
else:
  type BiggestUInt* = uint64
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is `uint32` for JS and `uint64` for other
    ## targets.

when defined(windows):
  type
    clong* {.importc: "long", nodecl.} = int32
      ## This is the same as the type `long` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint32
      ## This is the same as the type `unsigned long` in *C*.
else:
  type
    clong* {.importc: "long", nodecl.} = int
      ## This is the same as the type `long` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint
      ## This is the same as the type `unsigned long` in *C*.

type # these work for most platforms:
  cchar* {.importc: "char", nodecl.} = char
    ## This is the same as the type `char` in *C*.
  cschar* {.importc: "signed char", nodecl.} = int8
    ## This is the same as the type `signed char` in *C*.
  cshort* {.importc: "short", nodecl.} = int16
    ## This is the same as the type `short` in *C*.
  cint* {.importc: "int", nodecl.} = int32
    ## This is the same as the type `int` in *C*.
  csize* {.importc: "size_t", nodecl, deprecated: "use `csize_t` instead".} = int
    ## This isn't the same as `size_t` in *C*. Don't use it.
  csize_t* {.importc: "size_t", nodecl.} = uint
    ## This is the same as the type `size_t` in *C*.
  clonglong* {.importc: "long long", nodecl.} = int64
    ## This is the same as the type `long long` in *C*.
  cfloat* {.importc: "float", nodecl.} = float32
    ## This is the same as the type `float` in *C*.
  cdouble* {.importc: "double", nodecl.} = float64
    ## This is the same as the type `double` in *C*.
  clongdouble* {.importc: "long double", nodecl.} = BiggestFloat
    ## This is the same as the type `long double` in *C*.
    ## This C type is not supported by Nim's code generator.

  cuchar* {.importc: "unsigned char", nodecl, deprecated: "use `char` or `uint8` instead".} = char
    ## Deprecated: Use `uint8` instead.
  cushort* {.importc: "unsigned short", nodecl.} = uint16
    ## This is the same as the type `unsigned short` in *C*.
  cuint* {.importc: "unsigned int", nodecl.} = uint32
    ## This is the same as the type `unsigned int` in *C*.
  culonglong* {.importc: "unsigned long long", nodecl.} = uint64
    ## This is the same as the type `unsigned long long` in *C*.

proc toFloat*(i: int): float {.noSideEffect, inline.} =
  ## Converts an integer `i` into a `float`. Same as `float(i)`.
  ##
  ## If the conversion fails, `ValueError` is raised.
  ## However, on most platforms the conversion cannot fail.
  ##
  ##   ```
  ##   let
  ##     a = 2
  ##     b = 3.7
  ##
  ##   echo a.toFloat + b # => 5.7
  ##   ```
  float(i)

proc toBiggestFloat*(i: BiggestInt): BiggestFloat {.noSideEffect, inline.} =
  ## Same as `toFloat <#toFloat,int>`_ but for `BiggestInt` to `BiggestFloat`.
  BiggestFloat(i)

proc toInt*(f: float): int {.noSideEffect.} =
  ## Converts a floating point number `f` into an `int`.
  ##
  ## Conversion rounds `f` half away from 0, see
  ## `Round half away from zero
  ## <https://en.wikipedia.org/wiki/Rounding#Round_half_away_from_zero>`_,
  ## as opposed to a type conversion which rounds towards zero.
  ##
  ## Note that some floating point numbers (e.g. infinity or even 1e19)
  ## cannot be accurately converted.
  ##   ```
  ##   doAssert toInt(0.49) == 0
  ##   doAssert toInt(0.5) == 1
  ##   doAssert toInt(-0.5) == -1 # rounding is symmetrical
  ##   ```
  if f >= 0: int(f+0.5) else: int(f-0.5)

proc toBiggestInt*(f: BiggestFloat): BiggestInt {.noSideEffect.} =
  ## Same as `toInt <#toInt,float>`_ but for `BiggestFloat` to `BiggestInt`.
  if f >= 0: BiggestInt(f+0.5) else: BiggestInt(f-0.5)

const
  Inf* = 0x7FF0000000000000'f64
    ## Contains the IEEE floating point value of positive infinity.
  NegInf* = 0xFFF0000000000000'f64
    ## Contains the IEEE floating point value of negative infinity.
  NaN* = 0x7FF7FFFFFFFFFFFF'f64
    ## Contains an IEEE floating point value of *Not A Number*.
    ##
    ## Note that you cannot compare a floating point value to this value
    ## and expect a reasonable result - use the `isNaN` or `classify` procedure
    ## in the `math module <math.html>`_ for checking for NaN.

proc high*(T: typedesc[SomeFloat]): T = Inf
proc low*(T: typedesc[SomeFloat]): T = NegInf

{.push stackTrace: off.}

when defined(js):
  proc js_abs[T: SomeNumber](x: T): T {.importc: "Math.abs".}
else:
  proc c_fabs(x: cdouble): cdouble {.importc: "fabs", header: "<math.h>".}
  proc c_fabsf(x: cfloat): cfloat {.importc: "fabsf", header: "<math.h>".}

proc abs*[T: float64 | float32](x: T): T {.noSideEffect, inline.} =
  when nimvm:
    if x < 0.0: result = -x
    elif x == 0.0: result = 0.0 # handle 0.0, -0.0
    else: result = x # handle NaN, > 0
  else:
    when defined(js): result = js_abs(x)
    else:
      when T is float64:
        result = c_fabs(x)
      else:
        result = c_fabsf(x)

func abs*(x: int): int {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int8): int8 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int16): int16 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int32): int32 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int64): int64 {.magic: "AbsI", inline.} =
  ## Returns the absolute value of `x`.
  ##
  ## If `x` is `low(x)` (that is -MININT for its type),
  ## an overflow exception is thrown (if overflow checking is turned on).
  result = if x < 0: -x else: x

proc min*(x, y: float32): float32 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc min*(x, y: float64): float64 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc max*(x, y: float32): float32 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc max*(x, y: float64): float64 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc min*[T: not SomeFloat](x, y: T): T {.inline.} =
  if x <= y: x else: y
proc max*[T: not SomeFloat](x, y: T): T {.inline.} =
  if y <= x: x else: y

{.pop.} # stackTrace: off

proc `/`*(x, y: int): float {.inline, noSideEffect.} =
  ## Division of integers that results in a float.
  ##   ```
  ##   echo 7 / 5 # => 1.4
  ##   ```
  ##
  ## See also:
  ## * `div <system.html#div,int,int>`_
  ## * `mod <system.html#mod,int,int>`_
  result = toFloat(x) / toFloat(y)

proc `+%`*(x, y: int): int {.inline.} =
  ## Treats `x` and `y` as unsigned and adds them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.
  cast[int](cast[uint](x) + cast[uint](y))
proc `+%`*(x, y: int8): int8 {.inline.}   = cast[int8](cast[uint8](x) + cast[uint8](y))
proc `+%`*(x, y: int16): int16 {.inline.} = cast[int16](cast[uint16](x) + cast[uint16](y))
proc `+%`*(x, y: int32): int32 {.inline.} = cast[int32](cast[uint32](x) + cast[uint32](y))
proc `+%`*(x, y: int64): int64 {.inline.} = cast[int64](cast[uint64](x) + cast[uint64](y))

proc `-%`*(x, y: int): int {.inline.} =
  ## Treats `x` and `y` as unsigned and subtracts them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.
  cast[int](cast[uint](x) - cast[uint](y))
proc `-%`*(x, y: int8): int8 {.inline.}   = cast[int8](cast[uint8](x) - cast[uint8](y))
proc `-%`*(x, y: int16): int16 {.inline.} = cast[int16](cast[uint16](x) - cast[uint16](y))
proc `-%`*(x, y: int32): int32 {.inline.} = cast[int32](cast[uint32](x) - cast[uint32](y))
proc `-%`*(x, y: int64): int64 {.inline.} = cast[int64](cast[uint64](x) - cast[uint64](y))

proc `*%`*(x, y: int): int {.inline.} =
  ## Treats `x` and `y` as unsigned and multiplies them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.
  cast[int](cast[uint](x) * cast[uint](y))
proc `*%`*(x, y: int8): int8 {.inline.}   = cast[int8](cast[uint8](x) * cast[uint8](y))
proc `*%`*(x, y: int16): int16 {.inline.} = cast[int16](cast[uint16](x) * cast[uint16](y))
proc `*%`*(x, y: int32): int32 {.inline.} = cast[int32](cast[uint32](x) * cast[uint32](y))
proc `*%`*(x, y: int64): int64 {.inline.} = cast[int64](cast[uint64](x) * cast[uint64](y))

proc `/%`*(x, y: int): int {.inline.} =
  ## Treats `x` and `y` as unsigned and divides them.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.
  cast[int](cast[uint](x) div cast[uint](y))
proc `/%`*(x, y: int8): int8 {.inline.}   = cast[int8](cast[uint8](x) div cast[uint8](y))
proc `/%`*(x, y: int16): int16 {.inline.} = cast[int16](cast[uint16](x) div cast[uint16](y))
proc `/%`*(x, y: int32): int32 {.inline.} = cast[int32](cast[uint32](x) div cast[uint32](y))
proc `/%`*(x, y: int64): int64 {.inline.} = cast[int64](cast[uint64](x) div cast[uint64](y))

proc `%%`*(x, y: int): int {.inline.} =
  ## Treats `x` and `y` as unsigned and compute the modulo of `x` and `y`.
  ##
  ## The result is truncated to fit into the result.
  ## This implements modulo arithmetic. No overflow errors are possible.
  cast[int](cast[uint](x) mod cast[uint](y))
proc `%%`*(x, y: int8): int8 {.inline.}   = cast[int8](cast[uint8](x) mod cast[uint8](y))
proc `%%`*(x, y: int16): int16 {.inline.} = cast[int16](cast[uint16](x) mod cast[uint16](y))
proc `%%`*(x, y: int32): int32 {.inline.} = cast[int32](cast[uint32](x) mod cast[uint32](y))
proc `%%`*(x, y: int64): int64 {.inline.} = cast[int64](cast[uint64](x) mod cast[uint64](y))

when defined(nimNoZeroExtendMagic):
  proc ze*(x: int8): int {.deprecated.} =
    ## zero extends a smaller integer type to `int`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int](uint(cast[uint8](x)))

  proc ze*(x: int16): int {.deprecated.} =
    ## zero extends a smaller integer type to `int`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int](uint(cast[uint16](x)))

  proc ze64*(x: int8): int64 {.deprecated.} =
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint8](x)))

  proc ze64*(x: int16): int64 {.deprecated.} =
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint16](x)))

  proc ze64*(x: int32): int64 {.deprecated.} =
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint32](x)))

  proc ze64*(x: int): int64 {.deprecated.} =
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned. Does nothing if the size of an `int` is the same as `int64`.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int64](uint64(cast[uint](x)))

  proc toU8*(x: int): int8 {.deprecated.} =
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int8](x)

  proc toU16*(x: int): int16 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an `int16` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int16](x)

  proc toU32*(x: int64): int32 {.deprecated.} =
    ## treats `x` as unsigned and converts it to an `int32` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
    cast[int32](x)

elif not defined(js):
  proc ze*(x: int8): int {.magic: "Ze8ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze*(x: int16): int {.magic: "Ze16ToI", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int8): int64 {.magic: "Ze8ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int16): int64 {.magic: "Ze16ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int32): int64 {.magic: "Ze32ToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc ze64*(x: int): int64 {.magic: "ZeIToI64", noSideEffect, deprecated.}
    ## zero extends a smaller integer type to `int64`. This treats `x` as
    ## unsigned. Does nothing if the size of an `int` is the same as `int64`.
    ## (This is the case on 64 bit processors.)
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU8*(x: int): int8 {.magic: "ToU8", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to a byte by taking the last 8 bits
    ## from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU16*(x: int): int16 {.magic: "ToU16", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an `int16` by taking the last
    ## 16 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.

  proc toU32*(x: int64): int32 {.magic: "ToU32", noSideEffect, deprecated.}
    ## treats `x` as unsigned and converts it to an `int32` by taking the
    ## last 32 bits from `x`.
    ## **Deprecated since version 0.19.9**: Use unsigned integers instead.
