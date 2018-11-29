discard """
output: '''
AngelikaAnneAnnaAnkaAnja
AngelikaAnneAnnaAnkaAnja
AngelikaAnneAnnaAnkaAnja
onetwothree
onetwothree
onetwothree
one1two2three3
'''
"""
# Test the new implicit conversion from sequences to arrays in a constant
# context.

import strutils


block t1:
  const
    myWords = "Angelika Anne Anna Anka Anja".split()

  for x in items(myWords):
    write(stdout, x) #OUT AngelikaAnneAnnaAnkaAnja
  echo ""


block t2:
  const
    myWords = @["Angelika", "Anne", "Anna", "Anka", "Anja"]

  for i in 0 .. high(myWords):
    write(stdout, myWords[i]) #OUT AngelikaAnneAnnaAnkaAnja
  echo ""


block t3:
  for w in items(["Angelika", "Anne", "Anna", "Anka", "Anja"]):
    write(stdout, w) #OUT AngelikaAnneAnnaAnkaAnja
  echo ""


block t2656:
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
