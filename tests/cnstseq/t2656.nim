discard """
  output: '''onetwothreeonetwothreeonetwothree'''
"""

iterator it1(args: seq[string]): string =
  for s in args: yield s

iterator it2(args: seq[string]): string {.closure.} =
  for s in args: yield s

iterator it3(args: openArray[string]): string {.closure.} =
  for s in args: yield s

const myConstSeq = @["one", "two", "three"]
for s in it1(myConstSeq):
  stdout.write s
for s in it2(myConstSeq):
  stdout.write s
for s in it3(myConstSeq):
  stdout.write s
