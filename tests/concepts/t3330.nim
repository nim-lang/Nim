discard """
errormsg: "type mismatch: got (Bar[system.int])"
nimout: '''
t3330.nim(40, 4) Error: type mismatch: got (Bar[system.int])
but expected one of: 
proc test(foo: Foo[int])
t3330.nim(25, 8) Hint: Non-matching candidates for add(k, string, T)
proc add[T](x: var seq[T]; y: T)
proc add(result: var string; x: float)
proc add(x: var string; y: string)
proc add(x: var string; y: cstring)
proc add(x: var string; y: char)
proc add(result: var string; x: int64)
proc add[T](x: var seq[T]; y: openArray[T])

t3330.nim(25, 8) template/generic instantiation from here
t3330.nim(32, 6) Foo: 'bar.value' cannot be assigned to
t3330.nim(25, 8) template/generic instantiation from here
t3330.nim(33, 6) Foo: 'bar.x' cannot be assigned to
'''
"""

type
  Foo[T] = concept k
    add(k, string, T)

  Bar[T] = object
    value: T
    x: string

proc add[T](bar: Bar[T], x: string, val: T) =
  bar.value = val
  bar.x = x

proc test(foo: Foo[int]) =
  foo.add("test", 42)
  echo(foo.x)

var bar = Bar[int]()
bar.test()

