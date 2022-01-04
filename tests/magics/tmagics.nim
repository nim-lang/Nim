discard """
  output: '''
true
true
false
true
true
false
true
'''
joinable: false
"""

block tlowhigh:
  type myEnum = enum e1, e2, e3, e4, e5
  var a: array[myEnum, int]

  for i in low(a) .. high(a):
    a[i] = 0

  proc sum(a: openArray[int]): int =
    result = 0
    for i in low(a)..high(a):
      inc(result, a[i])

  doAssert sum([1, 2, 3, 4]) == 10


block t8693:
  type Foo = int | float

  proc bar(t1, t2: typedesc): bool =
    echo (t1 is t2)
    (t2 is t1)

  proc bar[T](x: T, t2: typedesc): bool =
    echo (T is t2)
    (t2 is T)

  doAssert bar(int, Foo) == false
  doAssert bar(4, Foo) == false
  doAssert bar(any, int)
  doAssert bar(int, any) == false
  doAssert bar(Foo, Foo)
  doAssert bar(any, Foo)
  doAssert bar(Foo, any) == false

block t9442:
  var v1: ref char
  var v2: string
  var v3: seq[char]
  GC_ref(v1)
  GC_unref(v1)
  GC_ref(v2)
  GC_unref(v2)
  GC_ref(v3)
  GC_unref(v3)

block: # bug #6499
  let x = (chr, 0)
  doAssert x[1] == 0

block: # bug #12229
  proc foo(T: typedesc) = discard
  foo(ref)
