discard """
  output: '''13 abc'''
"""

type
  PBinaryTree = ref object
    le, ri: PBinaryTree
    value: int


proc main =
  var x: PBinaryTree
  deepCopy(x, PBinaryTree(ri: PBinaryTree(le: PBinaryTree(value: 13))))
  var y: string
  deepCopy y, "abc"
  echo x.ri.le.value, " ", y

main()
