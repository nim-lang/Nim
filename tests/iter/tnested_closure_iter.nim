discard """
  output: '''0
1
2'''
"""
# bug #1725
iterator factory(): int {.closure.} =
  iterator bar(): int {.closure.} =
    yield 0
    yield 1
    yield 2

  for x in bar(): yield x

for x in factory():
  echo x
