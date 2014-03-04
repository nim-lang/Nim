discard """
  msg: '''1
2
3
1
2
3'''
"""

const s = @[1,2,3]

macro foo: stmt =
  for e in s:
    echo e

foo()

static:
  for e in s:
    echo e

