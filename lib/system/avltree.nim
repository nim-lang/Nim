#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## AVL balanced tree based on a C implementation by Julienne Walker

const 
  HeightLimit = 128        # Tallest allowable tree
  
# Two way single rotation 

template singleRot(root, dir: expr): stmt =
  block:
    var save = root.link[1-dir]
    root.link[1-dir] = save.link[dir]
    save.link[dir] = root
    root = save

# Two way double rotation 

template doubleRot(root, dir: expr): stmt =
  block:
    var save = root.link[1-dir].link[dir]
    root.link[1-dir].link[dir] = save.link[1-dir]
    save.link[1-dir] = root.link[1-dir]
    root.link[1-dir] = save
    save = root.link[1-dir]
    root.link[1-dir] = save.link[dir]
    save.link[dir] = root
    root = save

# Adjust balance before double rotation 

template adjustBalance(root, dir, bal: expr): stmt = 
  block:
    var n = root.link[dir]
    var nn = n.link[1-dir]
    if nn.balance == 0:
      root.balance = 0
      n.balance = 0
    elif nn.balance == bal:
      root.balance = -bal
      n.balance = 0
    else:
      # nn->balance == -bal 
      root.balance = 0
      n.balance = bal
    nn.balance = 0

# Rebalance after insertion 

template insertBalance(root, dir: expr): stmt = 
  block:
    var n = root.link[dir]
    var bal = if dir == 0: -1 else: +1
    if n.balance == bal:
      root.balance = 0
      n.balance = 0
      singleRot(root, 1-dir)
    else: 
      # n->balance == -bal 
      adjustBalance(root, dir, bal)
      doubleRot(root, 1-dir)

# Rebalance after deletion 

template removeBalance(root, dir, done: expr): stmt =
  block:
    var n = root.link[1-dir]
    var bal = if dir == 0: -1 else: + 1
    if n.balance == - bal: 
      root.balance = 0
      n.balance = 0
      singleRot(root, dir)
    elif n.balance == bal: 
      adjustBalance(root, 1-dir, - bal)
      doubleRot(root, dir)
    else: 
      # n->balance == 0 
      root.balance = -bal
      n.balance = bal
      singleRot(root, dir)
      done = true

proc find(root: PAvlNode, key: int): PAvlNode = 
  var it = root
  while it != nil:
    if it.key == key: return it
    it = it.link[ord(it.key < key)]

proc inRange(root: PAvlNode, key: int): PAvlNode =
  var it = root
  while it != nil:
    if it.key <= key and key <= it.upperBound: return it
    it = it.link[ord(it.key < key)]

proc contains(root: PAvlNode, key: int): bool {.inline.} =
  result = find(root, key) != nil

proc maxheight(n: PAvlNode): int =
  if n != nil:
    result = max(maxheight(n.link[0]), maxheight(n.link[1])) + 1

proc minheight(n: PAvlNode): int =
  if n != nil:
    result = min(minheight(n.link[0]), minheight(n.link[1])) + 1

proc lowGauge(n: PAvlNode): int =
  var it = n
  while it != nil:
    result = it.key
    it = it.link[0]
  
proc highGauge(n: PAvlNode): int =
  result = -1
  var it = n
  while it != nil:
    result = it.upperBound
    it = it.link[1]

proc add(a: var TMemRegion, key, upperBound: int) = 
  # Empty tree case
  if a.root == nil:
    a.root = allocAvlNode(a, key, upperBound)
  else:
    var head: TAvlNode # Temporary tree root
    var s, t, p, q: PAvlNode
    # Iterator and save pointer 
    var dir: int
    # Set up false root to ease maintenance:
    t = addr(head)
    t.link[1] = a.root
    # Search down the tree, saving rebalance points
    s = t.link[1]
    p = s
    while true:
      dir = ord(p.key < key)
      q = p.link[dir]
      if q == nil: break 
      if q.balance != 0:
        t = p
        s = q
      p = q
    q = allocAvlNode(a, key, upperBound)
    p.link[dir] = q
    # Update balance factors
    p = s
    while p != q:
      dir = ord(p.key < key)
      if dir == 0: dec p.balance
      else: inc p.balance
      p = p.link[dir]
    q = s
    # Save rebalance point for parent fix 
    # Rebalance if necessary 
    if abs(s.balance) > 1:
      dir = ord(s.key < key)
      insertBalance(s, dir)
    # Fix parent
    if q == head.link[1]: a.root = s
    else: t.link[ord(q == t.link[1])] = s

proc del(a: var TMemRegion, key: int) =
  if a.root == nil: return
  var
    upd: array[0..HeightLimit-1, int]
    up: array[0..HeightLimit-1, PAvlNode]
  var top = 0
  var it = a.root
  # Search down tree and save path
  while true:
    if it == nil: return
    elif it.key == key: break 
    # Push direction and node onto stack 
    upd[top] = ord(it.key < key)
    up[top] = it
    it = it.link[upd[top]]
    inc top
  # Remove the node 
  if it.link[0] == nil or it.link[1] == nil: 
    # Which child is not null? 
    var dir = ord(it.link[0] == nil)
    # Fix parent 
    if top != 0: up[top - 1].link[upd[top - 1]] = it.link[dir]
    else: a.root = it.link[dir]
    deallocAvlNode(a, it)
  else:
    # Find the inorder successor 
    var heir = it.link[1]
    # Save this path too 
    upd[top] = 1
    up[top] = it
    inc top
    while heir.link[0] != nil: 
      upd[top] = 0
      up[top] = heir
      inc top
      heir = heir.link[0]
    swap(it.key, heir.key)
    swap(it.upperBound, heir.upperBound)
    
    # Unlink successor and fix parent 
    up[top - 1].link[ord(up[top - 1] == it)] = heir.link[1]
    deallocAvlNode(a, heir)
  # Walk back up the search path
  dec top
  var done = false
  while top >= 0 and not done:
    # Update balance factors
    if upd[top] != 0: dec up[top].balance
    else: inc up[top].balance
    # Terminate or rebalance as necessary 
    if abs(up[top].balance) == 1: 
      break
    elif abs(up[top].balance) > 1: 
      removeBalance(up[top], upd[top], done)
      # Fix parent
      if top != 0: up[top-1].link[upd[top-1]] = up[top]
      else: a.root = up[0]
    dec top

when isMainModule:
  import math
  var
    r: PAvlNode
    s: seq[int]
  const N = 1000_000
  newSeq s, N

  for i in 0..N-1:
    var key = i #random(10_000)
    s[i] = key
    r.add(key, 12_000_000)
  for i in 0..N-1:
    var key = s[i]
    doAssert inRange(r, key+1000) != nil
    doAssert key in r
  echo "Min-Height: ", minheight(r), " max-height: ", maxheight(r)
  for i in 0..N-1:
    var key = s[i]
    del r, key
    doAssert key notin r
    
  doAssert r == nil

