discard """
  output: '''5
7'''
"""

# A pragma block used as an expression must preserve its value across a yield.
iterator gen(): int {.closure.} =
  let x = block:
    {.cast(gcsafe).}:
      yield 5
      7
  yield x

for v in gen(): echo v
