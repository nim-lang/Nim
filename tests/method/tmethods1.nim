discard """
  output: "do nothing"
"""

method somethin(obj: RootObj) {.base.} =
  echo "do nothing"

type
  TNode* = object {.inheritable.}
  PNode* = ref TNode

  PNodeFoo* = ref object of TNode

  TSomethingElse = object
  PSomethingElse = ref TSomethingElse

method foo(a: PNode, b: PSomethingElse) {.base.} = discard
method foo(a: PNodeFoo, b: PSomethingElse) = discard

var o: RootObj
o.somethin()

