discard """
  output: "do nothing"
"""

method somethin(obj: TObject) =
  echo "do nothing"

type
  TNode* = object {.inheritable.}
  PNode* = ref TNode

  PNodeFoo* = ref object of TNode

  TSomethingElse = object 
  PSomethingElse = ref TSomethingElse

method foo(a: PNode, b: PSomethingElse) = nil
method foo(a: PNodeFoo, b: PSomethingElse) = nil

var o: TObject
o.somethin()

