
type
  ListNode {.acyclic.} = ref object
    payload: string
    prev {.cursor.}: ListNode
    next: ListNode

  ManualList = ref object
    head, tail: ListNode
    len: int

  TreeNode {.acyclic.} = ref object
    parent: ManualList
    le: TreeNode
    ri: TreeNode
    self {.cursor.}: TreeNode

proc newManualList(): ManualList =
  ## Allocate an empty list structure in manual memory.
  result = ManualList()

proc append(list: ManualList; size: int) =
  ## Append a dummy payload node of the given size.
  if list.isNil:
    raise newException(ValueError, "list must be allocated before append")
  let node = ListNode()
  if list.head.isNil:
    list.head = node
    list.tail = node
  else:
    list.tail.next = node
    node.prev = list.tail
    list.tail = node
  inc list.len

proc buildTree(parent: ManualList; depth: int): TreeNode =
  ## Build a tree whose nodes live in manually managed memory.
  if depth <= 0:
    return nil
  let node = TreeNode()
  node.parent = parent
  if depth > 1:
    node.le = buildTree(parent, depth - 1)
    node.ri = buildTree(parent, depth - 2)
  node.self = node
  result = node

proc manualRun(iterations, listSize, payloadSize, depth, treeBuilds: int) =
  for _ in 0..<iterations:
    let leakList = newManualList()
    for _ in 0..<listSize:
      append(leakList, payloadSize)
    for _ in 0..<treeBuilds:
      let tree = buildTree(leakList, depth)

when isMainModule:
  manualRun(
    iterations = 100,
    listSize = 5000,
    payloadSize = 200,
    depth = 8,
    treeBuilds = 401
  )
