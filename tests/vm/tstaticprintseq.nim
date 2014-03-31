discard """
  msg: '''1
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
24'''
"""

const s = @[1,2,3]

macro foo: stmt =
  for e in s:
    echo e

foo()

static:
  for e in s:
    echo e

macro bar(x: static[seq[int]]): stmt =
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

macro ff(d: static[TData]): stmt =
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

