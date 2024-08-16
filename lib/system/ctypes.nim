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
