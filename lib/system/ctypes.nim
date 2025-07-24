## Some type definitions for compatibility between different
## backends and platforms.

type
  BiggestInt* = int64
    ## is an alias for the biggest signed integer type the Nim compiler
    ## supports. Currently this is `int64`, but it is platform-dependent
    ## in general.

  BiggestFloat* = float64
    ## is an alias for the biggest floating point type the Nim
    ## compiler supports. Currently this is `float64`, but it is
    ## platform-dependent in general.

  BiggestUInt* = uint64
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is `uint64`, but it is platform-dependent
    ## in general.

when defined(nimdoc):
  type
    # "Opaque" types defined only in the `nimdoc` branch to not show in error
    # messages in regular code with `clong` and `culong` resolving to base types
    ClongImpl = (when defined(windows): int32 else: int)
    CulongImpl = (when defined(windows): uint32 else: uint)
    clong* = ClongImpl
      ## Represents the *C* `long` type, used for interoperability.
      ##
      ## Its purpose is to match the *C* `long` for the target
      ## platform's Application Binary Interface (ABI).
      ##
      ## Typically, the compiler resolves it to one of the following Nim types
      ## based on the target:
      ## - `int32 <system.html#int32>`_ on Windows using MSVC or MinGW compilers.
      ## - `int <system.html#int>`_ on Linux, macOS and other platforms that use the
      ##    LP64 or ILP32 `data models
      ## <https://en.wikipedia.org/wiki/64-bit_computing#64-bit_data_models>`_.
      ##
      ## .. warning:: The underlying Nim type is an implementation detail and
      ##    should not be relied upon.
    culong* = CulongImpl
      ## Represents the *C* `unsigned long` type, used for interoperability.
      ##
      ## Its purpose is to match the *C* `unsigned long` for the target
      ## platform's Application Binary Interface (ABI).
      ##
      ## Typically, the compiler resolves it to one of the following Nim types
      ## based on the target:
      ## - `uint32 <system.html#uint32>`_ on Windows using MSVC or MinGW compilers.
      ## - `uint <system.html#uint>`_ on Linux, macOS and other platforms that use the
      ##    LP64 or ILP32 `data models
      ## <https://en.wikipedia.org/wiki/64-bit_computing#64-bit_data_models>`_.
      ##
      ## .. warning:: The underlying Nim type is an implementation detail and
      ##    should not be relied upon.
elif defined(windows):
  type
    clong* {.importc: "long", nodecl.} = int32
    culong* {.importc: "unsigned long", nodecl.} = uint32
else:
  type
    clong* {.importc: "long", nodecl.} = int
    culong* {.importc: "unsigned long", nodecl.} = uint

type # these work for most platforms:
  cchar* {.importc: "char", nodecl.} = char
    ## This is the same as the type `char` in *C*.
  cschar* {.importc: "signed char", nodecl.} = int8
    ## This is the same as the type `signed char` in *C*.
  cshort* {.importc: "short", nodecl.} = int16
    ## This is the same as the type `short` in *C*.
  cint* {.importc: "int", nodecl.} = int32
    ## This is the same as the type `int` in *C*.
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

  cuchar* {.importc: "unsigned char", nodecl, deprecated: "Use `char` or `uint8` instead".} = char
  cushort* {.importc: "unsigned short", nodecl.} = uint16
    ## This is the same as the type `unsigned short` in *C*.
  cuint* {.importc: "unsigned int", nodecl.} = uint32
    ## This is the same as the type `unsigned int` in *C*.
  culonglong* {.importc: "unsigned long long", nodecl.} = uint64
    ## This is the same as the type `unsigned long long` in *C*.

type
  ByteAddress* {.deprecated: "use `uint`".} = int
    ## is the signed integer type that should be used for converting
    ## pointers to integer addresses for readability.

  cstringArray* {.importc: "char**", nodecl.} = ptr UncheckedArray[cstring]
    ## This is binary compatible to the type `char**` in *C*. The array's
    ## high value is large enough to disable bounds checking in practice.
    ## Use `cstringArrayToSeq proc <#cstringArrayToSeq,cstringArray,Natural>`_
    ## to convert it into a `seq[string]`.

when not defined(nimPreviewSlimSystem):
  # pollutes namespace
  type
    PFloat32* {.deprecated: "use `ptr float32`".} = ptr float32
      ## An alias for `ptr float32`.
    PFloat64* {.deprecated: "use `ptr float64`".} = ptr float64
      ## An alias for `ptr float64`.
    PInt64* {.deprecated: "use `ptr int64`".} = ptr int64
      ## An alias for `ptr int64`.
    PInt32* {.deprecated: "use `ptr int32`".} = ptr int32
      ## An alias for `ptr int32`.
