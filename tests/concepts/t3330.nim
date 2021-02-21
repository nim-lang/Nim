discard """
errormsg: "type mismatch: got <Bar[system.int]>"
nimout: '''
t3330.nim(70, 4) Error: type mismatch: got <Bar[system.int]>
but expected one of:
proc test(foo: Foo[int])
  first type mismatch at position: 1
  required type for foo: Foo[int]
  but expression 'bar' is of type: Bar[system.int]
t3330.nim(55, 8) Hint: Non-matching candidates for add(k, string, T)
proc add(x: var string; y: char)
  first type mismatch at position: 1
  required type for x: var string
  but expression 'k' is of type: Alias
proc add(x: var string; y: cstring)
  first type mismatch at position: 1
  required type for x: var string
  but expression 'k' is of type: Alias
proc add(x: var string; y: string)
  first type mismatch at position: 1
  required type for x: var string
  but expression 'k' is of type: Alias
proc add[T](x: var seq[T]; y: openArray[T])
  first type mismatch at position: 1
  required type for x: var seq[T]
  but expression 'k' is of type: Alias
proc add[T](x: var seq[T]; y: sink T)
  first type mismatch at position: 1
  required type for x: var seq[T]
  but expression 'k' is of type: Alias

t3330.nim(55, 8) template/generic instantiation of `add` from here
t3330.nim(62, 6) Foo: 'bar.value' cannot be assigned to
t3330.nim(55, 8) template/generic instantiation of `add` from here
t3330.nim(63, 6) Foo: 'bar.x' cannot be assigned to

expression: test(bar)'''
"""













## line 60
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
