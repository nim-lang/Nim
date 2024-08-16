discard """
  output: '''
317
TEST2
5 5 5
false
'''
"""

import mbind_bracket, mclosed_sym, mdotlookup, mmodule_same_as_proc, mtypenodes


block tbind_bracket:
  # bug #2599
  # also test that `[]` can be passed now as a first class construct:

  template takeBracket(x, a, i: untyped) =
    echo x(a, i)

  var a: array[10, int]
  a[8] = 317

  takeBracket(`[]`, a, 8)

  let reg = newRegistry[UUIDObject]()
  reg.register(UUIDObject())


block tclosed_sym:
  # bug #2664
  proc same(r:R, d:int) = echo "TEST1"
  doIt(Data[int](d:123), R())

import strutils, unicode # ambiguous `strip`

block tdotlookup:
  foo(7)
  # bug #1444
  fn(4)
  doAssert doStrip(123) == "123"
  # bug #14254
  doAssert baz2[float](1'i8) == 1
  # bug #21883
  proc abc[T: not not int](x: T): T =
    var x = x
    x.set("hello", "world")
    result = x
  doAssert abc(5) == 10
  block: # ensure normal call is consistent with dot call 
    proc T(x: int): float = x.float
    proc foo[T](x: int) =
      doAssert typeof(T(x)) is typeof(x.T)
    foo[uint](123)

block tmodule_same_as_proc:
  # bug #1965
  proc test[T](t: T) =
    mmodule_same_as_proc"a"
  test(0)

block ttypenodes:
  # issue #22699
  doAssert chop[bool](42) == 42
