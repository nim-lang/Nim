discard """
output: '''
hello some integer
hello range
hello tuple
hello seq
hello object
hello distinct
hello enum
'''
"""



# SomeInteger

proc foo[T : SomeInteger](arg: T)
proc foo[T : SomeInteger](arg: T) =
  echo "hello some integer"
foo(123)

# range

proc foo2[T : range[0..100]](arg: T)
proc foo2[T : range[0..100]](arg: T) =
  echo "hello range"
foo2(7)

# tuple

proc foo3[T : tuple](arg: T)
proc foo3[T : tuple](arg: T) =
  echo "hello tuple"

foo3((a:123,b:321))

# seq

proc foo4[T: seq](arg: T)
proc foo4[T: seq](arg: T) =
  echo "hello seq"

foo4(@[1,2,3])

# object

proc foo5[T : object](arg: T)
proc foo5[T : object](arg: T) =
  echo "hello object"

type MyType = object
var mt: MyType
foo5(mt)

# distinct

proc foo6[T : distinct](arg: T)
proc foo6[T : distinct](arg: T) =
  echo "hello distinct"

type MyDistinct = distinct string
var md: MyDistinct
foo6(md)

# enum

proc foo7[T : enum](arg: T)
proc foo7[T : enum](arg: T) =
  echo "hello enum"

type MyEnum = enum
  ValueA
foo7(ValueA)
