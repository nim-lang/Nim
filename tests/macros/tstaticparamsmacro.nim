discard """
  nimout: '''
letters
aa
bb
numbers
11
22
AST a
[(11, 22), (33, 44)]
AST b
([55, 66], [77, 88])
55
10
20Test
20
'''
"""

import macros

type
  TConfig = tuple
    letters: seq[string]
    numbers:seq[int]

const data: Tconfig = (@["aa", "bb"], @[11, 22])

macro mymacro(data: static[TConfig]): untyped =
  echo "letters"
  for s in items(data.letters):
    echo s
  echo "numbers"
  for n in items(data.numbers):
    echo n

mymacro(data)

type
  Ta = seq[tuple[c:int, d:int]]
  Tb = tuple[e:seq[int], f:seq[int]]

const
  a : Ta = @[(11, 22), (33, 44)]
  b : Tb = (@[55,66], @[77, 88])

macro mA(data: static[Ta]): untyped =
  echo "AST a\n", repr(data)

macro mB(data: static[Tb]): untyped =
  echo "AST b\n", repr(data)
  echo data.e[0]

mA(a)
mB(b)

type
  Foo[N: static[int], Z: static[string]] = object

macro staticIntMacro(f: static[int]): untyped = echo f
staticIntMacro 10

var
  x: Foo[20, "Test"]

macro genericMacro[N; Z: static[string]](f: Foo[N, Z], ll = 3, zz = 12): untyped =
  echo N, Z

genericMacro x

template genericTemplate[N, Z](f: Foo[N, Z], ll = 3, zz = 12): int = N

static:
  echo genericTemplate(x)

