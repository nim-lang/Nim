discard """
  errormsg: "shared memory may not refer to GC'ed thread local memory"
  line: 14
  disabled: true
"""

type
  Region = object
  Foo = Region ptr int

  MyObject = object
    a, b: string

  Bar[T] = shared ptr T
  Bzar = Bar[MyObject]

proc bar(x: Region ptr int) =
  discard

var
  s: Foo

bar s
