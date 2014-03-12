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
aa
bb'''
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
  var m = data
  for x in m.letters:
    echo x

macro ff(d: static[TData]): stmt =
  for x in d.letters:
    echo x

ff(data)
