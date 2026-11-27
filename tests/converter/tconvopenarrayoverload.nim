discard """
  targets: "c js"
  output: '''
string
seq
["a","b"]
'''
"""

import std/json

converter toStr(c: char): string = $c

proc foo(s: string): string = "string"
proc foo[T](a: openArray[T]): string = "openArray"
echo foo('a')

type Dummy = object
  data: seq[int]

converter toSeq(x: Dummy): seq[int] = x.data

proc bar(s: seq[int]): string = "seq"
proc bar(a: openArray[int]): string = "openArray"
echo bar(Dummy(data: @[1]))

echo %(@['a', 'b'])
