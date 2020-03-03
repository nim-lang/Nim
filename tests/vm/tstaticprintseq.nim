discard """
  nimout: '''1
2
3
1
2
3
1
2
3
1
2
3
aa
bb
11
22
aa
bb
24
2147483647 2147483647
5'''
"""

const s = @[1,2,3]

macro foo() =
  for e in s:
    echo e

foo()

static:
  for e in s:
    echo e

macro bar(x: static[seq[int]]): untyped =
  for e in x:
    echo e

bar s
bar(@[1, 2, 3])

type
  TData = tuple
    letters: seq[string]
    numbers: seq[int]

const data: TData = (@["aa", "bb"], @[11, 22])

static:
  var m1 = data
  for x in m1.letters: echo x

  var m2: TData = data
  for x in m2.numbers: echo x

macro ff(d: static[TData]) =
  for x in d.letters:
    echo x

ff(data)

# bug #1010

proc `*==`(x: var int, y: int) {.inline, noSideEffect.} =
  ## Binary `*=` operator for ordinals
  x = x * y

proc fac: int =
  var x = 1;
  for i in 1..4:
    x *== i;
  return x

const y = fac()

static:
  echo y

static:
  var foo2 = int32.high
  echo foo2, " ", int32.high

# bug #1329

static:
    var a: ref int
    new(a)
    a[] = 5

    echo a[]
