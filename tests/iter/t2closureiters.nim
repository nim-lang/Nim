discard """
  output: '''1'''
"""
# bug #3837

iterator t1(): int {.closure.} =
  yield 1

iterator t2(): int {.closure.} =
  for i in t1():
    yield i

for i in t2():
  echo $i
