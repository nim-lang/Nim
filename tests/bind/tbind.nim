discard """
output: '''
3
1
TFoo1
TFoo2
Bar1
Bar2
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
    Bar1 = object
    Bar2 = object

  proc test(f: TFoo1) =
    echo "TFoo1"

  proc Foo[T](f: T) =
    mixin test
    test(f)

  var
    a: TFoo1
    b: TFoo2
    bar1: Bar1
    bar2: Bar2

  proc test(f: TFoo2) = echo "TFoo2"
  proc test(f: Bar1) = echo "Bar1"
  proc test(f: Bar2) = echo "Bar2"

  Foo(a)
  Foo(b)
  Foo(bar1)
  Foo(bar2)

# issue #11811
proc p(a : int) =
  echo a

proc printVar*[T:int|float|string](a : T) =
  bind p
  p(a)

printVar(5)
