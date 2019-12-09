discard """
output: '''
1
0
0
'''
"""
{.experimental: "notnil".}
type
  MyPointer = distinct pointer
  MyString = distinct string
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

var i: MyInt
i = 1.MyInt
doAssert(compiles(i = nil) == false)
