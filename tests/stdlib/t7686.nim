import std/strutils
import std/assertions

type
  MyEnum = enum
    A,
    a

doAssert parseEnum[MyEnum]("A") == A
doAssert parseEnum[MyEnum]("a") == a
