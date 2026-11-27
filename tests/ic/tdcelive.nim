discard """
  output: '''(1 abc (2 ) )
big 5 caught
true false
leaf 7'''
"""

# The per-module backend's merge stage keeps a definition only if something
# live uses it: compilerprocs, type infos (and their init procs) and consts are
# no liveness roots of their own. Every reference that the C text makes by an
# unmarked name must therefore show up as an explicit use, or the merge drops
# what the program still needs: the discriminator table filled by the type
# info's init, nested type infos, compilerprocs that codegen names directly.

import mdcelive

var tree = Node(kind: kNode, kids: @[Node(kind: kInt, i: 1),
  Node(kind: kStr, s: "abc"), Node(kind: kNode, kids: @[Node(kind: kInt, i: 2)])])
echo toStr(tree)
var n = Node(kind: kInt, i: 5)
makeBig(n)
echo toStr(n), " ", tryMakeStr(n)
let l: Node = Leaf(kind: kInt, i: 7, tag: "leaf")
echo l of Leaf, " ", tree of Leaf
echo Leaf(l).tag, " ", toStr(l)
