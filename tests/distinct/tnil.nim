discard """
  file: "tnil.nim"
  output: '''1
0
0
'''
"""
{.experimental: "notnil".}
type
  MyPointer = distinct pointer
  MyString = distinct string
  MyStringNotNil = distinct (string not nil)
  MyInt = distinct int

proc foo(a: MyPointer) =
  # workaround a Windows 'repr' difference:
  echo cast[int](a)

foo(cast[MyPointer](1))
foo(cast[MyPointer](nil))
foo(nil)

var p: MyPointer
p = cast[MyPointer](1)
p = cast[MyPointer](nil)
p = nil.MyPointer
p = nil

var c: MyString
c = "Test".MyString
c = nil.MyString
c = nil

p = nil
doAssert(compiles(c = p) == false)

var n: MyStringNotNil = "Test".MyStringNotNil # Cannot prove warning ...
n = "Test".MyStringNotNil
doAssert(compiles(n = nil.MyStringNotNil) == false)
doAssert(compiles(n = nil.MyStringNotNil) == false)
doAssert(compiles(n = nil) == false)

var i: MyInt
i = 1.MyInt
doAssert(compiles(i = nil) == false)
