discard """
  joinable: false
  output: '''
3 4 int64 7
a b 2
@[1, 2] 12
'''
"""

# The types of a cycle group's modules are checked before their other
# declarations, but a type section can still use what precedes it: these
# statements are checked right before the type sections.
import prereqs/mtype_prereqs {.cyclic.}

const useLarge = not defined(nimNoLarge)
when useLarge: # imports of a `when`, its condition needs a constant
  import std/sequtils

const N = 3

# a forward declared routine with effects in a cycle group: the call in
# `walk` must see the declared effects, not demand the body of `visit`
proc visit(n: int): int {.gcsafe, raises: [].}
proc walk(n: int): int =
  if n <= 0: 0 else: visit(n - 1) + 1
proc visit(n: int): int =
  if n <= 0: 0 else: walk(n - 1) + 1

var fromPartner = partnerValue() # not needed by a type: it keeps its place
template Int(): untyped = int64
{.pragma: myObj.}
var g = 1.5
when defined(js) or true:
  type Ui = uint8

type
  E* = enum a, b
  A* {.myObj.} = object
    arr*: array[N, int]
    x*: Int()
    f*: typeof(g)
    u*: Ui
    b*: ref B # of the partner module

const names: array[E, string] = ["a", "b"] # between type sections

type
  C* = array[E, string]


var x: A
echo x.arr.len, " ", sizeof(x.arr[0]) div 2, " ", $typeof(x.x), " ", fromPartner
let c: C = names
echo c[a], " ", c[b], " ", walk(2)
echo toSeq(1..2), " ", useB(B(y: 12))
