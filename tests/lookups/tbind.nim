discard """
output: '''
3
1
1
1
5
'''
"""


block tbind:
# Test the new ``bind`` keyword for templates

  proc p1(x: int8, y: int): int = return x + y

  template tempBind(x, y): untyped =
    bind p1
    p1(x, y)

  proc p1(x: int, y: int8): int = return x - y

  # This is tricky: the call to ``p1(1'i8, 2'i8)`` should not fail in line 6,
  # because it is not ambiguous there. But it is ambiguous after line 8.

  echo tempBind(1'i8, 2'i8) #OUT 3


import mbind3
echo genId() #OUT 1


import strtabs
block tbinoverload:
  template t() =
    block:
      bind newStringTable
      discard {"Content-Type": "text/html"}.newStringTable()

      discard {:}.newStringTable
  #discard {"Content-Type": "text/html"}.newStringTable()
  t()


block tmixin:
  type
    TFoo1 = object of RootObj
      v: int
    TFoo2 = object of TFoo1
      v2: int

  proc test(f: TFoo1) =
    echo "1"

  proc Foo[T](f: T) =
    mixin test
    test(f)

  var
    a: TFoo1
    b: TFoo2


  proc test(f: TFoo2) =
    echo "2"

  Foo(a)
  Foo(b)

# issue #11811
proc p(a : int) =
  echo a

proc printVar*[T:int|float|string](a : T) =
  bind p
  p(a)

printVar(5)
