discard """
  output: '''5
@[5, 10]'''
"""

# bug #12375: a closure in the body of a loop over an iterator that yields
# in both branches of `when nimvm`
import std/[os, sequtils, sugar]

iterator it(): int =
  when nimvm:
    yield 1
  else:
    yield 2

proc call(f: proc(x: int): int): int = f(1)

for file in it():
  let multiplier = 5
  echo call(proc(x: int): int = x * multiplier)

for k, file in walkDir("."):
  let multiplier = 5
  doAssert toSeq(1..2).map(x => x * multiplier) == @[5, 10]

for i in it():
  let multiplier = 5
  echo toSeq(1..2).map(x => x * multiplier)
