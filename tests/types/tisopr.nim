discard """
  output: '''true true false yes
false
false
false
true
true
yes'''
"""

proc IsVoid[T](): string =
  when T is void:
    result = "yes"
  else:
    result = "no"

const x = int is int
echo x, " ", float is float, " ", float is string, " ", IsVoid[void]()

template yes(e): void =
  static: assert e

template no(e): void =
  static: assert(not e)

when false:
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


# bug #2505

echo(8'i8 is int32)

# bug #1853
type SeqOrSet[E] = seq[E] or set[E]
type SeqOfInt = seq[int]
type SeqOrSetOfInt = SeqOrSet[int]

# This prints "false", which seems less correct that (1) printing "true" or (2)
# raising a compiler error.
echo seq is SeqOrSet

# This prints "false", as expected.
echo seq is SeqOrSetOfInt

# This prints "true", as expected.
echo SeqOfInt is SeqOrSet

# This causes an internal error (filename: compiler/semtypes.nim, line: 685).
echo SeqOfInt is SeqOrSetOfInt

# bug #2522
proc test[T](x: T) =
  when T is typedesc:
    echo "yes"
  else:
    echo "no"

test(7)
