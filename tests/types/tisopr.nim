discard """
  output: '''true true false yes'''
"""

proc IsVoid[T](): string =
  when T is void:
    result = "yes"
  else:
    result = "no"

const x = int is int
echo x, " ", float is float, " ", float is string, " ", IsVoid[void]()

template yes(e: expr): stmt =
  static: assert e

template no(e: expr): stmt =
  static: assert(not e)

var s = @[1, 2, 3]

yes s.items is iterator
no  s.items is proc

yes s.items is iterator: int
no  s.items is iterator: float

yes s.items is iterator: TNumber
no  s.items is iterator: object

type
  Iter[T] = iterator: T

yes s.items is Iter[TNumber]
no  s.items is Iter[float]

type
  Foo[N: static[int], T] = object
    field: array[1..N, T]

  Bar[T] = Foo[4, T]
  Baz[N: static[int]] = Foo[N, float]

no Foo[2, float] is Foo[3, float]
no Foo[2, float] is Foo[2, int]

yes Foo[4, string] is Foo[4, string]
yes Bar[int] is Foo[4, int]
yes Foo[4, int] is Bar[int]

no Foo[4, int] is Baz[4]
yes Foo[4, float] is Baz[4]

