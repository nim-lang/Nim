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
  M = 512    # max children per B-tree node = M-1
             # (must be even and greater than 2)
  Mhalf = M div 2

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

proc initBTree*[Key, Val](): BTree[Key, Val] =
  BTree[Key, Val](root: Node[Key, Val](entries: 0, isInternal: false))

template less(a, b): bool = cmp(a, b) < 0
template eq(a, b): bool = cmp(a, b) == 0

proc getOrDefault*[Key, Val](b: BTree[Key, Val], key: Key): Val =
  var x = b.root
  while x.isInternal:
    for j in 0 ..< x.entries:
      if j+1 == x.entries or less(key, x.keys[j+1]):
        x = x.links[j]
        break
  assert(not x.isInternal)
  for j in 0 ..< x.entries:
    if eq(key, x.keys[j]): return x.vals[j]

proc contains*[Key, Val](b: BTree[Key, Val], key: Key): bool =
  var x = b.root
  while x.isInternal:
    for j in 0 ..< x.entries:
      if j+1 == x.entries or less(key, x.keys[j+1]):
        x = x.links[j]
        break
  assert(not x.isInternal)
  for j in 0 ..< x.entries:
    if eq(key, x.keys[j]): return true
  return false

proc copyHalf[Key, Val](h, result: Node[Key, Val]) =
  for j in 0 ..< Mhalf:
    result.keys[j] = h.keys[Mhalf + j]
  if h.isInternal:
    for j in 0 ..< Mhalf:
      result.links[j] = h.links[Mhalf + j]
  else:
    for j in 0 ..< Mhalf:
      shallowCopy(result.vals[j], h.vals[Mhalf + j])

proc split[Key, Val](h: Node[Key, Val]): Node[Key, Val] =
  ## split node in half
  result = Node[Key, Val](entries: Mhalf, isInternal: h.isInternal)
  h.entries = Mhalf
  copyHalf(h, result)

proc insert[Key, Val](h: Node[Key, Val], key: Key, val: Val): Node[Key, Val] =
  #var t = Entry(key: key, val: val, next: nil)
  var newKey = key
  var j = 0
  if not h.isInternal:
    while j < h.entries:
      if less(key, h.keys[j]): break
      inc j
    for i in countdown(h.entries, j+1):
      shallowCopy(h.vals[i], h.vals[i-1])
    h.vals[j] = val
  else:
    var newLink: Node[Key, Val] = nil
    while j < h.entries:
      if j+1 == h.entries or less(key, h.keys[j+1]):
        let u = insert(h.links[j], key, val)
        inc j
        if u == nil: return nil
        newKey = u.keys[0]
        newLink = u
        break
      inc j
    for i in countdown(h.entries, j+1):
      h.links[i] = h.links[i-1]
    h.links[j] = newLink

  for i in countdown(h.entries, j+1):
    h.keys[i] = h.keys[i-1]
  h.keys[j] = newKey
  inc h.entries
  return if h.entries < M: nil else: split(h)

proc add*[Key, Val](b: var BTree[Key, Val]; key: Key; val: Val) =
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

proc toString[Key, Val](h: Node[Key, Val], indent: string; result: var string) =
  if not h.isInternal:
    for j in 0..<h.entries:
      result.add(indent)
      result.add($h.keys[j] & " " & $h.vals[j] & "\n")
  else:
    for j in 0..<h.entries:
      if j > 0: result.add(indent & "(" & $h.keys[j] & ")\n")
      toString(h.links[j], indent & "   ", result)

proc `$`[Key, Val](b: BTree[Key, Val]): string =
  result = ""
  toString(b.root, "", result)

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

  import random, tables

  proc main =
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
    assert st.getOrDefault("www.harvardsucks.com") == nil

    assert st.getOrDefault("www.simpsons.com") == "209.052.165.60"
    assert st.getOrDefault("www.apple.com") == "17.112.152.32"
    assert st.getOrDefault("www.ebay.com") == "66.135.192.87"
    assert st.getOrDefault("www.dell.com") == "143.166.224.230"
    assert(st.entries == 16)

    for k, v in st:
      echo k, ": ", v

    when false:
      var b2 = initBTree[string, string]()
      const iters = 10_000
      for i in 1..iters:
        b2.add($i, $(iters - i))
      for i in 1..iters:
        let x = b2.getOrDefault($i)
        if x != $(iters - i):
          echo "got ", x, ", but expected ", iters - i
      echo b2.entries

    when true:
      var b2 = initBTree[int, string]()
      var t2 = initTable[int, string]()
      const iters = 100_000
      for i in 1..iters:
        let x = rand(high(int))
        if not t2.hasKey(x):
          doAssert b2.getOrDefault(x).len == 0, " what, tree has this element " & $x
          t2[x] = $x
          b2.add(x, $x)

      doAssert b2.entries == t2.len
      echo "unique entries ", b2.entries
      for k, v in t2:
        doAssert $k == v
        doAssert b2.getOrDefault(k) == $k

  main()
