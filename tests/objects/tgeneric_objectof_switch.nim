discard """
  matrix: "--mm:arc; --mm:refc"
  output: '''
leaf
node
leaf
node
'''
"""

type
  Base[T] = ref object of RootObj
  Leaf[T] = ref object of Base[T]
  Node[T] = ref object of Base[T]

proc classify[T](x: Base[T]) =
  if x of Leaf[T]:
    echo "leaf"
  elif x of Node[T]:
    echo "node"
  else:
    echo "other"

proc expectLeaf[T](x: Base[T]) =
  discard Leaf[T](x)
  echo "leaf"

proc expectNode[T](x: Base[T]) =
  discard Node[T](x)
  echo "node"

classify[int](Leaf[int]())
classify[int](Node[int]())
expectLeaf[int](Leaf[int]())
expectNode[int](Node[int]())
