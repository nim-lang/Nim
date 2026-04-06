discard """
  targets: "c cpp"
  output: "ok"
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
  doAssertRaises(ObjectConversionDefect):
    discard LeftLeaf(z)

echo "ok"
