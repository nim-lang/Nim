{.experimental: "notnil".}
type
  MyPointer = distinct pointer
  MyString = distinct string
  MyInt = distinct int

proc foo(a: MyPointer): int =
  # workaround a Windows 'repr' difference:
  cast[int](a)

doAssert foo(cast[MyPointer](1)) == 1
doAssert foo(cast[MyPointer](nil)) == 0
doAssert foo(MyPointer(nil)) == 0

var p: MyPointer
p = cast[MyPointer](1)
p = cast[MyPointer](nil)
p = nil.MyPointer

var i: MyInt
i = 1.MyInt
doAssert(compiles(i = nil) == false)
