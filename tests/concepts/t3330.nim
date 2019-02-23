discard """
errormsg: "type mismatch: got <Bar[system.int]>"
disabled: "true"
nimout: '''
t3330.nim(63, 4) Error: type mismatch: got <Bar[system.int]>
but expected one of:
proc test(foo: Foo[int])
t3330.nim(48, 8) Hint: Non-matching candidates for add(k, string, T)
proc add[T](x: var seq[T]; y: openArray[T])
  first type mismatch at position: 1
  required type: var seq[T]
  but expression 'k' is of type: Alias
proc add(result: var string; x: float)
  first type mismatch at position: 1
  required type: var string
  but expression 'k' is of type: Alias
proc add(x: var string; y: string)
  first type mismatch at position: 1
  required type: var string
  but expression 'k' is of type: Alias
proc add(x: var string; y: cstring)
  first type mismatch at position: 1
  required type: var string
  but expression 'k' is of type: Alias
proc add[T](x: var seq[T]; y: T)
  first type mismatch at position: 1
  required type: var seq[T]
  but expression 'k' is of type: Alias
proc add(result: var string; x: int64)
  first type mismatch at position: 1
  required type: var string
  but expression 'k' is of type: Alias
proc add(x: var string; y: char)
  first type mismatch at position: 1
  required type: var string
  but expression 'k' is of type: Alias

t3330.nim(48, 8) template/generic instantiation of `add` from here
t3330.nim(55, 6) Foo: 'bar.value' cannot be assigned to
t3330.nim(48, 8) template/generic instantiation of `add` from here
t3330.nim(56, 6) Foo: 'bar.x' cannot be assigned to

expression: test(bar)'''
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

