discard """
  output: '''ok'''
  cmd: '''nim c --gc:orc -d:useMalloc -d:nimStressOrc $file'''
  valgrind: "leaks"
"""

# bug #15753

type
  NodeKind = enum
    nkDancing,
    nkColumn

  DancingNode = ref object
    right: DancingNode
    column: DancingNode
    kind: NodeKind

proc newColumnNode(): DancingNode =
  result = DancingNode(kind: nkColumn)
  result.right = result
  result.column = result

proc createDLXList(): DancingNode =
  result = newColumnNode()

  for i in 0 .. 15:
    let n = newColumnNode()
    n.right = result.right
    result = n
  echo "ok"

var dlxlist = createDLXList()
