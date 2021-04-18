discard """
  nimout: "tcheckedfield1.nim(39, 6) Warning: cannot prove that field 'x.s' is accessible [ProveField]"
  action: run
  output: "abc abc"
"""

import strutils

{.warning[ProveField]: on.}
{.experimental: "notnil".}
type
  TNodeKind = enum
    nkBinary, nkTernary, nkStr
  PNode = ref TNode not nil
  TNode = object
    case k: TNodeKind
    of nkBinary, nkTernary: a, b: PNode
    of nkStr: s: string

  PList = ref object
    data: string
    next: PList

proc getData(x: PList not nil) =
  echo x.data

var head: PList

proc processList() =
  var it = head
  while it != nil:
    getData(it)
    it = it.next

proc toString2(x: PNode): string =
  if x.k < nkStr:
    toString2(x.a) & " " & toString2(x.b)
  else:
    x.s

proc toString(x: PNode): string =
  case x.k
  of nkTernary, nkBinary:
    toString(x.a) & " " & toString(x.b)
  of nkStr:
    x.s

proc toString3(x: PNode): string =
  if x.k <= nkBinary:
    toString3(x.a) & " " & toString3(x.b)
  else:
    x.s # x.k in {nkStr}  --> fact:  not (x.k <= nkBinary)

proc p() =
  var x: PNode = PNode(k: nkStr, s: "abc")

  let y = x
  if not y.isNil:
    echo toString(y), " ", toString2(y)

p()
