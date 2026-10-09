discard """
  output: '''
a.s=@[4] b.s=@[1, 2, 3] c=@[9, 9, 9]
@[4] @[9, 9, 9]
@[4] @[9, 9, 9]
kb
'''
  matrix: "--mm:orc -d:useMalloc; --mm:arc -d:useMalloc"
  valgrind: "true"
"""

# bug #26369: `=wasMoved` of a nested case object must reset the branch
# fields before it resets the discriminator that selects them.

import std/tables

type
  O = object
    case kind: bool
    of false: discard
    of true:
      case sub: bool
      of false: discard
      of true: s: seq[int]

proc viaMove() =
  var a = O(kind: true, sub: true, s: @[1, 2, 3])
  var b = a
  a = O(kind: true, sub: true, s: @[4])
  var c = @[9, 9, 9]
  echo "a.s=", a.s, " b.s=", b.s, " c=", c

proc viaReset() =
  var a = O(kind: true, sub: true, s: @[1, 2, 3])
  reset(a)
  a = O(kind: true, sub: true, s: @[4])
  var c = @[9, 9, 9]
  echo a.s, " ", c

proc viaTable() =
  var t = initTable[int, O]()
  t[1] = O(kind: true, sub: true, s: @[1, 2, 3])
  t.del(1)
  t[1] = O(kind: true, sub: true, s: @[4])
  var c = @[9, 9, 9]
  echo t[1].s, " ", c

# `=wasMoved` must also reset the fields of the branch that the reset
# discriminator selects: `H`'s hook leaves bytes that overlap `s`.
type
  H = object
    p: int
    v: int
  K = enum ka, kb
  P = object
    case kind: K
    of ka: s: seq[int]
    of kb: h: H

proc `=wasMoved`(x: var H) = x.p = 0

proc consume(x: sink P) = echo x.kind

proc viaHook() =
  var o = P(kind: kb, h: H(p: 12345, v: 0x1234567))
  if o.kind == kb: consume o

viaMove()
viaReset()
viaTable()
viaHook()
