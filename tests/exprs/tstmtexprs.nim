discard """
  output: '''(bar: bar)
1244
6
abcdefghijklmnopqrstuvwxyz
145 23'''
"""

import strutils

when true:
  proc test(foo: proc (x, y: int): bool) =
    echo foo(5, 5)


  type Foo = object
    bar: string

  proc newfoo(): Foo =
    result.bar = "bar"

  echo($newfoo())
   

  proc retInt(x, y: int): int = 
    if (var yy = 0; yy != 0):
      echo yy
    else:
      echo(try: parseInt("1244") except EINvalidValue: -1)
    result = case x
             of 23: 3
             of 64: 
                    case y
                    of 1: 2
                    of 2: 3
                    of 3: 6
                    else: 8
             else: 1

  echo retInt(64, 3)

  proc buildString(): string =
    result = ""
    for x in 'a'..'z':
      result.add(x)

  echo buildString()

#test(
#  proc (x, y: int): bool =
#  if x == 5: return true
#  if x == 2: return false
#  if y == 78: return true
#)

proc q(): int {.discardable.} = 145
proc p(): int =
  q()

proc p2(a: int): int =
  # result enforces a void context:
  if a == 2:
    result = 23
  q()

echo p(), " ", p2(2)

proc semiProblem() =
  if false: echo "aye"; echo "indeed"

semiProblem()


# bug #844

import json 
proc parseResponse(): PJsonNode =
  result = % { "key1": % { "key2": % "value" } }
  for key, val in result["key1"]:
    var excMsg = key & "("
    if (var n=result["key2"]; n != nil):
      excMsg &= n.str
    raise newException(ESynch, excMsg)
