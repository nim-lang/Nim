discard """
  output: '''(x: 'a')'''
"""

type
  Bar[T] = object
    x: T

proc infer(T: typeDesc): Bar[T] = Bar[T](x: 'a')

let foo = infer(char)
echo foo

when true:
  # bug #1783

  type
      uoffset_t* = uint32
      FlatBufferBuilder* = object

      Array* [T] = object
          o*: uoffset_t
          len*: int
          data*: ptr UncheckedArray[T]

  proc ca* (fbb: ptr FlatBufferBuilder, T: typedesc, len: int): Array[T] {.noinit.} =
      result.len = len

  var fbb: ptr FlatBufferBuilder
  let boolarray = ca(fbb, bool, 2)
  let boolarray2 = fbb.ca(bool, 2)

# bug #1664
type Point[T] = tuple[x, y: T]
proc origin(T: typedesc): Point[T] = discard
discard origin(int)

block: # issue #12704
  const a = $("a", "b")
  proc fun() =
    const str = $int
    let b = $(str, "asdf")
  fun()

# https://github.com/nim-lang/Nim/issues/7516
import typetraits

block: #issue #12704
  const a = $("a", "b")
  proc fun() =
    const str = name(int)
    let b = $(str, "asdf")
  fun()

proc hasDefault1(T: type = int): auto = return T.name
doAssert hasDefault1(int) == "int"
doAssert hasDefault1(string) == "string"
doAssert hasDefault1() == "int"

proc hasDefault2(T = string): auto = return T.name
doAssert hasDefault2(int) == "int"
doAssert hasDefault2(string) == "string"
doAssert hasDefault2() == "string"


# bug #9195
type
  Error = enum
    erA, erB, erC
  Result[T, U] = object
    x: T
    u: U
  PB = object

proc decodeUVarint*(itzzz: typedesc[SomeUnsignedInt],
                    data: openArray[char]): Result[itzzz, Error] =
  result = Result[itzzz, Error](x: 0, u: erC)

discard decodeUVarint(uint32, "abc")

type
  X = object
  Y[T] = object

proc testObj(typ: typedesc[object]): Y[typ] =
  discard

discard testObj(X)


#bug 12804
import typetraits
discard int.name[0]