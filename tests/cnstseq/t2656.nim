discard """
  output: '''
onetwothree
onetwothree
onetwothree
one1two2three3
'''
"""

iterator it1(args: seq[string]): string =
  for s in args: yield s
iterator it2(args: seq[string]): string {.closure.} =
  for s in args: yield s
iterator it3(args: openArray[string]): string {.closure.} =
  for s in args: yield s
iterator it4(args: openArray[(string, string)]): string {.closure.} =
  for s1, s2 in items(args): yield s1 & s2

block:
  const myConstSeq = @["one", "two", "three"]
  for s in it1(myConstSeq):
    stdout.write s
  echo ""
  for s in it2(myConstSeq):
    stdout.write s
  echo ""
  for s in it3(myConstSeq):
    stdout.write s
  echo ""

block:
  const myConstSeq = @[("one", "1"), ("two", "2"), ("three", "3")]
  for s in it4(myConstSeq):
    stdout.write s
  echo ""
