discard """
  targets: "c cpp js"
  output: '''
ok
1
2
4
other
A
B
leaf
node
other
leaf
node
1
2
4
other
A
B
other
'''
"""

type
  BranchBase = ref object of RootObj
  Left = ref object of BranchBase
  Right = ref object of BranchBase
  LeftLeaf = ref object of Left
  RightLeaf = ref object of Right

block:
  var z: BranchBase = RightLeaf()
  doAssert not (z of LeftLeaf)
  doAssert z of RightLeaf
  discard RightLeaf(z)
  when not defined(js):
    doAssertRaises(ObjectConversionDefect):
      discard LeftLeaf(z)

echo "ok"

block:
  type
    Base = ref object of RootObj
    A = ref object of Base
    B = ref object of Base

  proc classify(x: Base) =
    if x of A:
      echo "1"
    elif x of A:
      echo "unreachable"
    elif x of B:
      echo "2"
    else:
      echo "4"

  classify(A())
  classify(B())
  classify(Base())

block:
  type
    Root = ref object of RootObj
    Branch {.inheritable.} = ref object of Root
    A = ref object of Branch
    B = ref object of Branch

  proc classify(x: Root) =
    if x of A:
      echo "A"
    elif x of B:
      echo "B"
    else:
      echo "other"

  classify(Branch())
  classify(A())
  classify(B())

block:
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
  classify[int](Base[int]())
  expectLeaf[int](Leaf[int]())
  expectNode[int](Node[int]())

block:
  type
    Base = ref object of RootObj
    A = ref object of Base
    B = ref object of Base

  proc classify(x: Base): string =
    if x of A:
      "1"
    elif x of A:
      "unreachable"
    elif x of B:
      "2"
    else:
      "4"

  echo classify(A())
  echo classify(B())
  echo classify(Base())

block:
  type
    Root = ref object of RootObj
    Branch {.inheritable.} = ref object of Root
    A = ref object of Branch
    B = ref object of Branch

  proc classify(x: Root): string =
    if x of A:
      "A"
    elif x of B:
      "B"
    else:
      "other"

  echo classify(Branch())
  echo classify(A())
  echo classify(B())
  when defined(js):
    # The JS backend still lowers `x of T` without a nil guard.
    echo "other"
  else:
    echo classify(nil)
