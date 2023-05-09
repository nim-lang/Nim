discard """
output: '''
1
0
Whopie
12
1.7'''
"""

echo len([1_000_000]) #OUT 1

type
  TArray = array[0..3, int]
  TVector = distinct array[0..3, int]
proc `[]`(v: TVector; idx: int): int = TArray(v)[idx]
var v: TVector
echo v[2]

# bug #569

import deques

type
  TWidget = object
    names: Deque[string]

var w = TWidget(names: initDeque[string]())

addLast(w.names, "Whopie")

for n in w.names: echo(n)

# bug #681

type TSomeRange = object
  hour: range[0..23]

var value: string
var val12 = TSomeRange(hour: 12)

value = $(if val12.hour > 12: val12.hour - 12 else: val12.hour)
echo value

# bug #1334

var ys = @[4.1, 5.6, 7.2, 1.7, 9.3, 4.4, 3.2]
#var x = int(ys.high / 2) #echo ys[x] # Works
echo ys[int(ys.high / 2)] # Doesn't work


# bug #19680
var here = ""
when stderr is static:
  doAssert false
else:
  here = "works"

doAssert here == "works"
