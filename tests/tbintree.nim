type
  TBinaryTree[T] = object      # TBinaryTree is a generic type with
                               # with generic param ``T``
    le, ri: ref TBinaryTree[T] # left and right subtrees; may be nil
    data: T                    # the data stored in a node
  PBinaryTree*[T] = ref TBinaryTree[T] # type that is exported

proc newNode*[T](data: T): PBinaryTree[T] =
  # constructor for a node
  new(result)
  result.dat = data

proc add*[T](root: var PBinaryTree[T], n: PBinaryTree[T]) =
  # insert a node into the tree
  if root == nil:
    root = n
  else:
    var it = root
    while it != nil:
      # compare the data items; uses the generic ``cmd`` proc that works for
      # any type that has a ``==`` and ``<`` operator
      var c = cmp(it.data, n.data)
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

proc add*[T](root: var PBinaryTree[T], data: T) =
  # convenience proc:
  add(root, newNode(data))

iterator preorder*[T](root: PBinaryTree[T]): T =
  # Preorder traversal of a binary tree.
  # Since recursive iterators are not yet implemented,
  # this uses an explicit stack:
  var stack: seq[PBinaryTree[T]] = @[root]
  while stack.len > 0:
    var n = stack[stack.len-1]
    setLen(stack, stack.len-1) # pop `n` of the stack
    while n != nil:
      yield n
      add(stack, n.ri)  # push right subtree onto the stack
      n = n.le          # and follow the left pointer

var
  root: PBinaryTree[string] # instantiate a PBinaryTree with the type string
add(root, newNode("hallo")) # instantiates generic procs ``newNode`` and ``add``
#add(root, "world")          # instantiates the second ``add`` proc
#for str in preorder(root):
#  stdout.writeln(str)

#OUT halloworld

