discard """
  output: '''hello
world
99
110
223'''
"""
type
  TBinaryTree[T] = object      # TBinaryTree is a generic type with
                               # with generic param ``T``
    le, ri: ref TBinaryTree[T] # left and right subtrees; may be nil
    data: T                    # the data stored in a node
  PBinaryTree*[A] = ref TBinaryTree[A] # type that is exported

proc newNode*[T](data: T): PBinaryTree[T] =
  # constructor for a node
  new(result)
  result.data = data

proc add*[Ty](root: var PBinaryTree[Ty], n: PBinaryTree[Ty]) =
  # insert a node into the tree
  if root == nil:
    root = n
  else:
    var it = root
    while it != nil:
      # compare the data items; uses the generic ``cmp`` proc that works for
      # any type that has a ``==`` and ``<`` operator
      var c = cmp(n.data, it.data)
      if c < 0:
        if it.le == nil:
          it.le = n
          return
        it = it.le
      else:
        if it.ri == nil:
          it.ri = n
          return
        it = it.ri

proc add*[Ty](root: var PBinaryTree[Ty], data: Ty) =
  # convenience proc:
  add(root, newNode(data))

proc find*[Ty2](b: PBinaryTree[Ty2], data: Ty2): bool =
  # for testing this needs to be recursive, so that the
  # instantiated type is checked for proper tyGenericInst envelopes
  if b == nil:
    result = false
  else:
    var c = cmp(data, b.data)
    if c < 0: result = find(b.le, data)
    elif c > 0: result = find(b.ri, data)
    else: result = true

iterator preorder*[T](root: PBinaryTree[T]): T =
  # Preorder traversal of a binary tree.
  # This uses an explicit stack (which is more efficient than
  # a recursive iterator factory).
  var stack: seq[PBinaryTree[T]] = @[root]
  while stack.len > 0:
    var n = stack.pop()
    while n != nil:
      yield n.data
      add(stack, n.ri)  # push right subtree onto the stack
      n = n.le          # and follow the left pointer

iterator items*[T](root: PBinaryTree[T]): T =
  ## Inorder traversal of the binary tree.
  var stack: seq[PBinaryTree[T]] = @[]
  var n = root
  while true:
    while n != nil:
      add(stack, n)
      n = n.le
    if stack.len > 0:
      n = stack.pop()
      yield n.data
      n = n.ri
    if stack.len == 0 and n == nil: break

proc debug[T](a: PBinaryTree[T]) =
  if a != nil:
    debug(a.le)
    echo a.data
    debug(a.ri)

when true:
  var
    root: PBinaryTree[string]
    x = newNode("hello")
  add(root, x)
  add(root, "world")
  if find(root, "world"):
    for str in items(root):
      echo(str)
  else:
    echo("BUG")

  var
    r2: PBinaryTree[int]
  add(r2, newNode(110))
  add(r2, 223)
  add(r2, 99)
  for y in items(r2):
    echo(y)
