
type
  ListNodeObj = object
    payload: string
    prev, next: ListNode

  ListNode = ptr ListNodeObj

  ManualListObj = object
    head, tail: ListNode
    len: int

  ManualList = ptr ManualListObj

  TreeNodeObj = object
    parent: ManualList
    le, ri: TreeNode
    self: TreeNode

  TreeNode = ptr TreeNodeObj

proc newManualList(): ManualList =
  ## Allocate an empty list structure in manual memory.
  result = cast[ManualList](alloc0(sizeof(ManualListObj)))

proc append(list: ManualList; size: int) =
  ## Append a dummy payload node of the given size.
  if list.isNil:
    raise newException(ValueError, "list must be allocated before append")
  let node = cast[ListNode](alloc0(sizeof(ListNodeObj)))
  if list.head.isNil:
    list.head = node
    list.tail = node
  else:
    list.tail.next = node
    node.prev = list.tail
    list.tail = node
  inc list.len

proc destroyList(list: ManualList) =
  ## Release list nodes and their payloads, then the list itself.
  if list.isNil:
    return
  var current = list.head
  while current != nil:
    let next = current.next
    dealloc(current)
    current = next
  dealloc(list)

proc buildTree(parent: ManualList; depth: int): TreeNode =
  ## Build a tree whose nodes live in manually managed memory.
  if depth <= 0:
    return nil
  let node = cast[TreeNode](alloc0(sizeof(TreeNodeObj)))
  node.parent = parent
  if depth > 1:
    node.le = buildTree(parent, depth - 1)
    node.ri = buildTree(parent, depth - 2)
  node.self = node
  result = node

proc destroyTree(root: TreeNode) =
  ## Recursively dispose nodes allocated by buildTree.
  if root.isNil:
    return
  destroyTree(root.le)
  destroyTree(root.ri)
  dealloc(root)

proc manualRun(iterations, listSize, payloadSize, depth, treeBuilds: int) =
  for _ in 0..<iterations:
    let leakList = newManualList()
    for _ in 0..<listSize:
      append(leakList, payloadSize)
    for _ in 0..<treeBuilds:
      let tree = buildTree(leakList, depth)
      destroyTree(tree)
    destroyList(leakList)

when isMainModule:
  manualRun(
    iterations = 100,
    listSize = 5000,
    payloadSize = 200,
    depth = 8,
    treeBuilds = 401
  )
