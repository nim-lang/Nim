discard """
  output: '''0
0
0
0
[[a = "",
b = []]]'''
"""

# bug #1475
type
  Crash = object
    a: string
    b: seq[string]

proc initCrash(): Crash = discard

proc test() =
  var blongname = [initCrash()]
  echo repr(blongname)

# bug #1434
proc bug: array[1, int] = discard

echo bug()[0]
echo bug()[0]
echo bug()[0]
echo bug()[0]

test()
