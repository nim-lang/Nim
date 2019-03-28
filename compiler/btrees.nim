#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## BTree implementation with few features, but good enough for the
## Nim compiler's needs.

const
  M = 4  # max children per B-tree node
          # (must be even and greater than 2)
  Mhalf = M div 2

import algorithm

type
  Node[Key, Val] = ref object
    entries: int
    keys: array[M, Key]
    case isInternal: bool
    of false:
      vals: array[M, Val]
    of true:
      links: array[M, Node[Key, Val]]
  BTree*[Key, Val] = object
    root: Node[Key, Val]
    entries: int      ## number of key-value pairs

proc sanityCheck[Key, Val](self: Node[Key,Val], isRoot: bool): int =
  if self.entries > M:
    echo "number of entries exceepds capacity ", self.entries
    result = -1
  if self.entries < Mhalf:
    if not isRoot or self.isInternal:
      echo "number of entries is below minimum ", self.entries
      echo self.keys[0]
      echo "---"
      return -1
  if self.isInternal:

    let expectedChildDepth = sanityCheck(self.links[0], false)
    if expectedChildDepth < 0:
      return -1

    for i in 1 ..< self.entries:
      let child = self.links[i]
      let childDepth = sanityCheck(child, false)
      if childDepth == -1:
        result = -1
      elif childDepth != expectedChildDepth:
        echo "node is imbalanced"
        return -1

    if result != -1:
      result =  expectedChildDepth + 1
  else:
    result = 1

proc sanityCheck[Key, Val](self: BTree[Key, Val]): bool =
  result = sanityCheck(self.root, true) > 0

proc toString[Key, Val](h: Node[Key, Val], indent: string; result: var string) =
  if not h.isInternal:
    for j in 0..<h.entries:
      result.add(indent)
      result.add($h.keys[j] & " " & $h.vals[j] & "\n")
  else:
    for j in 0..<h.entries:
      result.add(indent & "(" & $h.keys[j] & ")\n")
      toString(h.links[j], indent & "   ", result)

proc `$`[Key, Val](n: Node[Key, Val]): string =
  result = ""
  toString(n, "", result)

proc `$`[Key, Val](b: BTree[Key, Val]): string =
  result = ""
  toString(b.root, "", result)

proc initBTree*[Key, Val](): BTree[Key, Val] =
  discard

template less(a, b): bool = cmp(a, b) < 0
template eq(a, b): bool = cmp(a, b) == 0

proc findLinearWithCmp[T](arg: openarray[T]; entries: int; value: T): int =
  for i in 0 ..< entries:
    if eq(arg[i], value):
      return i
  return -1

proc newTreeFromSortedData[Key,Val](data: openArray[(Key,Val)]): BTree[Key,Val] =
  if data.len == 0:
    return

  var nodes = newSeq[Node[Key,Val]]()

  var currentNode: Node[Key,Val] = nil
  for i, (key, val) in data.pairs:
    if currentNode == nil:
      currentNode.new
    currentNode.keys[currentNode.entries] = key
    currentNode.vals[currentNode.entries] = val
    inc currentNode.entries
    if currentNode.entries == M or i == data.len-1:
      nodes.add currentNode
      currentNode = nil

  var newNodes: seq[Node[Key,Val]]
  while nodes.len > 1:
    newNodes.setLen 0
    swap(newNodes, nodes)
    for i, node in newNodes:
      if currentNode == nil:
        currentNode.new
        currentNode.isInternal = true
      currentNode.keys[currentNode.entries]  = node.keys[0]
      currentNode.links[currentNode.entries] = node
      inc currentNode.entries
      if currentNode.entries == M or i == newNodes.len:
        nodes.add currentNode
        currentNode = nil


  result.root = nodes[0]
  result.entries = data.len


proc findValue[T](values: openarray[T]; entries: int; value: T): int =
  # let expected = findLinearWithCmp(values, entries, value)

  if less(value, values[0]):
    #doAssert expected == -1
    return -1
  if less(values[entries-1], value):
    #doAssert expected == -1
    return -1

  var a = 0
  var b = entries-1
  while a != b:
    let mid = (a + b) div 2
    if cmp(value, values[mid]) <= 0:
      b = mid
    else:
      a = mid + 1
  if eq(values[a], value):
    result = a
  else:
    result = -1

  #doAssert result == expected

proc findKeyLinear[T](keys: openarray[T]; entries: int; key: T): int =
  if entries == 0 or less(key, keys[0]):
    return -1
  var i = 1
  while i < entries:
    if less(key, keys[i]):
      return i - 1
    inc i
  return entries-1

proc findKey[T](keys: openarray[T]; entries: int; key: T): int =
  if entries == 0 or less(key, keys[0]):
    return -1
  var a = 1
  var b = entries
  while a != b:
    let mid = (a + b) div 2
    if less(key, keys[mid]):
      b = mid
    else:
      a = mid + 1
  return a - 1

proc getOrDefault*[Key, Val](b: BTree[Key, Val], key: Key): Val =
  if b.root == nil:
    return
  var x = b.root
  while x.isInternal:
    let idx = findKey(x.keys, x.entries, key)
    if idx >= 0:
      x = x.links[idx]
    else:
      return
  assert(not x.isInternal)
  for j in 0 ..< x.entries:
    if eq(key, x.keys[j]): return x.vals[j]

proc contains*[Key, Val](n: BTree[Key, Val], key: Key): bool =
  if n.root == nil:
    return false
  var x = n.root
  while x.isInternal:
    let idx = findKey(x.keys, x.entries, key)
    if idx < 0:
      return false
    x = x.links[idx]
  assert(not x.isInternal)
  return findValue(x.keys, x.entries, key) >= 0


# for bootstrapping it can happen that ``default`` doesn't exist yet.
when not defined(nimHasDefault):
  template default(T: typedesc): untyped =
    var tmp: T
    tmp

proc split[Key, Val](h: Node[Key, Val]): Node[Key, Val] =
  ## modifiy h, to be half the size. Returns a node with the other half.
  result = Node[Key, Val](entries: Mhalf, isInternal: h.isInternal)
  h.entries = Mhalf

  for j in 0 ..< Mhalf:
    result.keys[j] = h.keys[Mhalf + j]
  if h.isInternal:
    for j in 0 ..< Mhalf:
      result.links[j] = h.links[Mhalf + j]
      h.links[Mhalf + j] = nil
  else:
    for j in 0 ..< Mhalf:
      shallowCopy(result.vals[j], h.vals[Mhalf + j])
      h.vals[Mhalf + j] = default(Val)

proc insert[Key, Val](h: Node[Key, Val], key: Key, val: Val): Node[Key, Val] =
  ## If h needs to be split, one half will remain in h, the other half
  ## is returned as a new node. Returns ``nil`` when no split occurs.

  var newKey = key
  var dstNode = h # node where insertion finally happens

  if h.isInternal:
    let idx = findKey(h.keys, h.entries, key)
    let newLink: Node[Key, Val] = insert(h.links[max(0, idx)], key, val)
    if idx < 0: # insertion to the very beginning
      h.keys[0] = h.links[0].keys[0]

    if newLink != nil:
      let newKey = newLink.keys[0]
      var newIdx = max(0, idx) + 1

      if h.entries == M:
        result = split(h)
        if less(key, result.keys[0]):
          dstNode = h
        else:
          dstNode = result
          newIdx -= Mhalf

      inc dstNode.entries
      rotateLeft(dstNode.links, newIdx ..< dstNode.entries, -1) # rotate right
      dstNode.links[newIdx] = newLink
      rotateLeft(dstNode.keys, newIdx ..< dstNode.entries, -1) # rotate right
      dstNode.keys[newIdx] = newKey
  else:
    # split if necessary
    if h.entries == M:
      result = split(h)
      if less(key, result.keys[0]):
        dstNode = h
      else:
        dstNode = result

    let idx = findKey(dstNode.keys, dstNode.entries, key) + 1
    inc dstNode.entries
    rotateLeft(dstNode.vals, idx ..< dstNode.entries, -1) # rotate right
    dstNode.vals[idx] = val
    rotateLeft(dstNode.keys, idx ..< dstNode.entries, -1) # rotate right
    dstNode.keys[idx] = newKey

proc delete[Key, Val](n: Node[Key, Val]; key: Key): bool =
  if n.isInternal:
    for j in 0 ..< n.entries:
      if j+1 == n.entries or less(key, n.keys[j+1]):
        let link = n.links[j]
        result = delete(link, key)
        if link.entries == 0:
          n.keys[j] = default(Key)
          rotateLeft(n.keys,  j ..< n.entries, 1)
          n.links[j] = nil
          rotateLeft(n.links, j ..< n.entries, 1)
          dec n.entries
        else:
          n.keys[j] = link.keys[0]
        return
  else:
    var idx = findValue(n.keys, n.entries, key)
    if idx >= 0:
      result = true
      n.keys[idx] = default(Key)
      rotateLeft(n.keys, idx ..< n.entries, 1)
      n.vals[idx] = default(Val)
      rotateLeft(n.vals, idx ..< n.entries, 1)
      dec n.entries

proc delete*[Key, Val](self: var BTree[Key, Val]; key: Key): bool =
  if self.root == nil:
    return false
  else:
    result = delete(self.root, key)
    dec self.entries
    if self.root.entries == 0:
      self.root = nil
      assert self.entries == 0

proc add*[Key, Val](b: var BTree[Key, Val]; key: Key; val: Val) =
  if b.root == nil:
    b.root = Node[Key, Val](entries: 0, isInternal: false)

  let u = insert(b.root, key, val)
  inc b.entries
  if u == nil: return

  # need to split root
  let t = Node[Key, Val](entries: 2, isInternal: true)
  t.keys[0] = b.root.keys[0]
  t.links[0] = b.root
  t.keys[1] = u.keys[0]
  t.links[1] = u
  b.root = t

proc hasNext*[Key, Val](b: BTree[Key, Val]; index: int): bool =
  result = index < b.entries

proc countSubTree[Key, Val](it: Node[Key, Val]): int =
  if it.isInternal:
    result = 0
    for k in 0..<it.entries:
      inc result, countSubTree(it.links[k])
  else:
    result = it.entries

proc next*[Key, Val](b: BTree[Key, Val]; index: int): (Key, Val, int) =
  var it = b.root
  var i = index
  # navigate to the right leaf:
  while it.isInternal:
    var sum = 0
    for k in 0..<it.entries:
      let c = countSubTree(it.links[k])
      inc sum, c
      if sum > i:
        it = it.links[k]
        dec i, (sum - c)
        break
  result = (it.keys[i], it.vals[i], index+1)

iterator pairs*[Key, Val](b: BTree[Key, Val]): (Key, Val) =
  var i = 0
  while hasNext(b, i):
    let (k, v, i2) = next(b, i)
    i = i2
    yield (k, v)

proc len*[Key, Val](b: BTree[Key, Val]): int {.inline.} = b.entries

when isMainModule:

  import random, tables, times, strutils

  template time(name: string; body: untyped): untyped =
    let startTime = getTime()
    body
    let timeDiff = inNanoseconds(getTime() - startTime)
    echo name, ": ", repeat("*", int(100 * timeDiff.float64 / 250000000.0)).align(60) & align($timeDiff, 10)

  proc main() =

    block test1:
      var st = initBTree[string, string]()
      st.add("www.cs.princeton.edu", "abc")
      st.add("www.princeton.edu",    "128.112.128.15")
      st.add("www.yale.edu",         "130.132.143.21")
      st.add("www.simpsons.com",     "209.052.165.60")
      st.add("www.apple.com",        "17.112.152.32")
      st.add("www.amazon.com",       "207.171.182.16")
      st.add("www.ebay.com",         "66.135.192.87")
      st.add("www.cnn.com",          "64.236.16.20")
      st.add("www.google.com",       "216.239.41.99")
      st.add("www.nytimes.com",      "199.239.136.200")
      st.add("www.microsoft.com",    "207.126.99.140")
      st.add("www.dell.com",         "143.166.224.230")
      st.add("www.slashdot.org",     "66.35.250.151")
      st.add("www.espn.com",         "199.181.135.201")
      st.add("www.weather.com",      "63.111.66.11")
      st.add("www.yahoo.com",        "216.109.118.65")

      assert st.getOrDefault("www.cs.princeton.edu") == "abc"
      assert st.getOrDefault("www.harvardsucks.com") == ""

      assert st.getOrDefault("www.simpsons.com") == "209.052.165.60"
      assert st.getOrDefault("www.apple.com") == "17.112.152.32"
      assert st.getOrDefault("www.ebay.com") == "66.135.192.87"
      assert st.getOrDefault("www.dell.com") == "143.166.224.230"
      assert(st.entries == 16)

      # echo st
      assert st.sanityCheck

      var keys: seq[string]

      for k, v in st:
        echo k, ": ", v
        keys.add k

      for key in keys:
        discard st.delete(key)

    when false:
      var b2 = initBTree[string, string]()
      const iters = 10_000
      for i in 1..iters:
        b2.add($i, $(iters - i))
      for i in 1..iters:
        let x = b2.getOrDefault($i)
        if x != $(iters - i):
          echo "got ", x, ", but expected ", iters - i

    when true:

      var keyValuePairs: seq[(string, int)]

      # I just happen to know that the random number generator doesn't produce collisions
      for i in 0 ..< 10000:
        var x = rand(high(int))
        keyValuePairs.add(($x,x))

      var t2 = initTable[string, int]()
      time "hash map fill  ":
        for (key, val) in keyValuePairs.items:
          t2[key] = val

      #sort keys
      time "hash map read  ":
        for (key, val) in keyValuePairs.items:
          doAssert t2[key] == val


      var tree = initBTree[string, int]()

      #for key, value in t2:
      time "tree fill      ":
        for key, val in keyValuePairs.items:
          #doAssert tree.getOrDefault(key) == "", " what, tree has this element " & $key
          #echo key
          tree.add(key, val)
          #doAssert tree.getOrDefault(key) == value
          #doAssert sanityCheck tree

      sort(keyValuePairs, proc (a,b: (string,int)): int = cmp(a[0], b[0]))

      time "tree fill bulk ":
        tree = newTreeFromSortedData(keyValuePairs)

      echo tree
      doAssert tree.entries == t2.len

      time "tree read      ":
        for (key, value) in keyValuePairs.items:
          doAssert tree.getOrDefault(key) == value, key

      shuffle(keyValuePairs)  # just make it a different order than insertion order


      time "delete all     ":
        for (key, value) in keyValuePairs.items:
          #doAssert key in tree
          doAssert tree.delete(key)
          #doAssert sanityCheck tree
          #doAssert key notin tree

      doAssert tree.entries == 0
      shuffle keyValuePairs

      time "readding all   ":
        for key, val in keyValuePairs.items:
          tree.add(key, val)


  main()
