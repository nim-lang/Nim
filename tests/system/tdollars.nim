discard """
  targets: "c cpp js"
"""

#[
if https://github.com/nim-lang/Nim/pull/14043 is merged (or at least its
tests/system/tostring.nim diff subset), merge
tests/system/tostring.nim into this file, named after dollars.nim

The goal is to increase test coverage across backends while minimizing test code
duplication (which always results in weaker test coverage in practice).
]#

import std/unittest
template test[T](a: T, expected: string) =
  check $a == expected
  var b = a
  check $b == expected
  static:
    doAssert $a == expected

template testType(T: typedesc) =
  when T is bool:
    test true, "true"
    test false, "false"
  elif T is char:
    test char, "\0"
    test char.high, static($T.high)
  else:
    test T.default, "0"
    test 1.T, "1"
    test T.low, static($T.low)
    test T.high, static($T.high)

block: # `$`(SomeInteger)
  # direct tests
  check $0'u8 == "0"
  check $255'u8 == "255"
  check $(-127'i8) == "-127"

  # known limitation: Error: number out of range: '128'i8',
  # see https://github.com/timotheecour/Nim/issues/125
  # check $(-128'i8) == "-128"

  check $int8.low == "-128"
  check $int8(-128) == "-128"
  when not defined js: # pending https://github.com/nim-lang/Nim/issues/14127
    check $cast[int8](-128) == "-128"

  var a = 12345'u16
  check $a == "12345"
  check $12345678'u64 == "12345678"
  check $12345678'i64 == "12345678"
  check $(-12345678'i64) == "-12345678"

  # systematic tests
  testType uint8
  testType uint16
  testType uint32
  testType uint

  testType int8
  testType int16
  testType int32

  testType int
  testType bool

  when not defined(js): # requires BigInt support
    testType uint64
    testType int64
    testType BiggestInt

block: # #14350 for JS
  var cstr: cstring
  doAssert cstr == cstring(nil)
  doAssert cstr == nil
  doAssert cstr.isNil
  doAssert cstr != cstring("")
