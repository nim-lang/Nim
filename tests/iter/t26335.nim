discard """
  output: '''
5
7
1
2
10
11
12
'''
"""

# bug #26335: yield inside an expression pragma block crashes the compiler

iterator gen(): int {.closure.} =
  let x = block:
    {.cast(gcsafe).}:
      yield 5
      7
  yield x

for v in gen(): echo v

iterator gen2(): int {.closure.} =
  let y = 1 + (block:
    {.cast(raises: []).}:
      yield 1
      1)
  yield y

for v in gen2(): echo v

import std/asyncdispatch

proc value(): Future[int] {.async.} =
  result = 11

proc main() {.async.} =
  let x = block:
    {.cast(gcsafe).}:
      echo 10
      await value()
  echo x
  echo x + 1

waitFor main()
