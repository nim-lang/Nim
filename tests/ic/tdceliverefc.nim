discard """
  output: '''(1 abc )
big 5 caught
true false
leaf 7
(1 abc ) 1'''
"""

# `tdcelive` under refc (see `tdceliverefc_temp.nim.cfg`): there the V1 type
# infos are what the GC and `deepCopy` read, and their init procs must run
# whenever a type info is live.

import mdcelive

var tree = Node(kind: kNode, kids: @[Node(kind: kInt, i: 1),
  Node(kind: kStr, s: "abc")])
echo toStr(tree)
var n = Node(kind: kInt, i: 5)
makeBig(n)
echo toStr(n), " ", tryMakeStr(n)
let l: Node = Leaf(kind: kInt, i: 7, tag: "leaf")
echo l of Leaf, " ", tree of Leaf
echo Leaf(l).tag, " ", toStr(l)
var copy: Node
deepCopy(copy, tree)
tree.kids.setLen 1
GC_fullCollect()
echo toStr(copy), " ", tree.kids.len
