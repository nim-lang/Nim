#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a `crit bit tree`:idx: which is an efficient
## container for a sorted set of strings, or for a sorted mapping of strings. Based on the excellent paper
## by Adam Langley.
## (A crit bit tree is a form of `radix tree`:idx: or `patricia trie`:idx:.)

import std/private/since

type
  NodeObj[T] {.acyclic.} = object
    byte: int ## byte index of the difference
    otherBits: char
    case isLeaf: bool
    of false: child: array[0..1, ref NodeObj[T]]
    of true:
      key: string
      when T isnot void:
        val: T

  Node[T] = ref NodeObj[T]
  CritBitTree*[T] = object ## The crit bit tree can either be used
                           ## as a mapping from strings to
                           ## some type ``T`` or as a set of
                           ## strings if ``T`` is void.
    root: Node[T]
    count: int

proc len*[T](c: CritBitTree[T]): int =
  ## Returns the number of elements in `c` in O(1).
  runnableExamples:
    var c: CritBitTree[void]
    incl(c, "key1")
    incl(c, "key2")
    doAssert c.len == 2

  result = c.count

proc rawGet[T](c: CritBitTree[T], key: string): Node[T] =
  var it = c.root
  while it != nil:
    if not it.isLeaf:
      let ch = if it.byte < key.len: key[it.byte] else: '\0'
      let dir = (1 + (ch.ord or it.otherBits.ord)) shr 8
      it = it.child[dir]
    else:
      return if it.key == key: it else: nil

proc contains*[T](c: CritBitTree[T], key: string): bool {.inline.} =
  ## Returns true if `c` contains the given `key`.
  runnableExamples:
    var c: CritBitTree[void]
    incl(c, "key")
    doAssert c.contains("key")

  result = rawGet(c, key) != nil

proc hasKey*[T](c: CritBitTree[T], key: string): bool {.inline.} =
  ## Alias for `contains <#contains,CritBitTree[T],string>`_.
  result = rawGet(c, key) != nil

proc rawInsert[T](c: var CritBitTree[T], key: string): Node[T] =
  if c.root == nil:
    c.root = Node[T](isleaf: true, key: key)
    result = c.root
  else:
    var it = c.root
    while not it.isLeaf:
      let ch = if it.byte < key.len: key[it.byte] else: '\0'
      let dir = (1 + (ch.ord or it.otherBits.ord)) shr 8
      it = it.child[dir]

    var newOtherBits = 0
    var newByte = 0
    block blockX:
      while newByte < key.len:
        let ch = if newByte < it.key.len: it.key[newByte] else: '\0'
        if ch != key[newByte]:
          newOtherBits = ch.ord xor key[newByte].ord
          break blockX
        inc newByte
      if newByte < it.key.len:
        newOtherBits = it.key[newByte].ord
      else:
        return it
    while (newOtherBits and (newOtherBits-1)) != 0:
      newOtherBits = newOtherBits and (newOtherBits-1)
    newOtherBits = newOtherBits xor 255
    let ch = if newByte < it.key.len: it.key[newByte] else: '\0'
    let dir = (1 + (ord(ch) or newOtherBits)) shr 8

    var inner: Node[T]
    new inner
    result = Node[T](isLeaf: true, key: key)
    inner.otherBits = chr(newOtherBits)
    inner.byte = newByte
    inner.child[1 - dir] = result

    var wherep = addr(c.root)
    while true:
      var p = wherep[]
      if p.isLeaf: break
      if p.byte > newByte: break
      if p.byte == newByte and p.otherBits.ord > newOtherBits: break
      let ch = if p.byte < key.len: key[p.byte] else: '\0'
      let dir = (1 + (ch.ord or p.otherBits.ord)) shr 8
      wherep = addr(p.child[dir])
    inner.child[dir] = wherep[]
    wherep[] = inner
  inc c.count

proc exclImpl[T](c: var CritBitTree[T], key: string): int =
  var p = c.root
  var wherep = addr(c.root)
  var whereq: ptr Node[T] = nil
  if p == nil: return c.count
  var dir = 0
  var q: Node[T]
  while not p.isLeaf:
    whereq = wherep
    q = p
    let ch = if p.byte < key.len: key[p.byte] else: '\0'
    dir = (1 + (ch.ord or p.otherBits.ord)) shr 8
    wherep = addr(p.child[dir])
    p = wherep[]
  if p.key == key:
    # else: not in tree at all
    if whereq == nil:
      c.root = nil
    else:
      whereq[] = q.child[1 - dir]
    dec c.count

  return c.count

proc excl*[T](c: var CritBitTree[T], key: string) =
  ## Removes `key` (and its associated value) from the set `c`.
  ## If the `key` does not exist, nothing happens.
  ##
  ## See also:
  ## * `incl proc <#incl,CritBitTree[void],string>`_
  ## * `incl proc <#incl,CritBitTree[T],string,T>`_
  runnableExamples:
    var c: CritBitTree[void]
    incl(c, "key")
    excl(c, "key")
    doAssert not c.contains("key")

  discard exclImpl(c, key)

proc missingOrExcl*[T](c: var CritBitTree[T], key: string): bool =
  ## Returns true if `c` does not contain the given `key`. If the key
  ## does exist, c.excl(key) is performed.
  ##
  ## See also:
  ## * `excl proc <#excl,CritBitTree[T],string>`_
  ## * `containsOrIncl proc <#containsOrIncl,CritBitTree[T],string,T>`_
  ## * `containsOrIncl proc <#containsOrIncl,CritBitTree[void],string>`_
  runnableExamples:
    block:
      var c: CritBitTree[void]
      doAssert c.missingOrExcl("key")
    block:
      var c: CritBitTree[void]
      incl(c, "key")
      doAssert not c.missingOrExcl("key")
      doAssert not c.contains("key")

  let oldCount = c.count
  discard exclImpl(c, key)
  result = c.count == oldCount

proc containsOrIncl*[T](c: var CritBitTree[T], key: string, val: T): bool =
  ## Returns true if `c` contains the given `key`. If the key does not exist
  ## ``c[key] = val`` is performed.
  ##
  ## See also:
  ## * `incl proc <#incl,CritBitTree[void],string>`_
  ## * `incl proc <#incl,CritBitTree[T],string,T>`_
  ## * `containsOrIncl proc <#containsOrIncl,CritBitTree[void],string>`_
  ## * `missingOrExcl proc <#missingOrExcl,CritBitTree[T],string>`_
  runnableExamples:
    block:
      var c: CritBitTree[int]
      doAssert not c.containsOrIncl("key", 42)
      doAssert c.contains("key")
    block:
      var c: CritBitTree[int]
      incl(c, "key", 21)
      doAssert c.containsOrIncl("key", 42)
      doAssert c["key"] == 21

  let oldCount = c.count
  var n = rawInsert(c, key)
  result = c.count == oldCount
  when T isnot void:
    if not result: n.val = val

proc containsOrIncl*(c: var CritBitTree[void], key: string): bool =
  ## Returns true if `c` contains the given `key`. If the key does not exist
  ## it is inserted into `c`.
  ##
  ## See also:
  ## * `incl proc <#incl,CritBitTree[void],string>`_
  ## * `incl proc <#incl,CritBitTree[T],string,T>`_
  ## * `containsOrIncl proc <#containsOrIncl,CritBitTree[T],string,T>`_
  ## * `missingOrExcl proc <#missingOrExcl,CritBitTree[T],string>`_
  runnableExamples:
    block:
      var c: CritBitTree[void]
      doAssert not c.containsOrIncl("key")
      doAssert c.contains("key")
    block:
      var c: CritBitTree[void]
      incl(c, "key")
      doAssert c.containsOrIncl("key")

  let oldCount = c.count
  discard rawInsert(c, key)
  result = c.count == oldCount

proc inc*(c: var CritBitTree[int]; key: string, val: int = 1) =
  ## Increments `c[key]` by `val`.
  runnableExamples:
    var c: CritBitTree[int]
    c["key"] = 1
    inc(c, "key")
    doAssert c["key"] == 2

  var n = rawInsert(c, key)
  inc n.val, val

proc incl*(c: var CritBitTree[void], key: string) =
  ## Includes `key` in `c`.
  ##
  ## See also:
  ## * `excl proc <#excl,CritBitTree[T],string>`_
  ## * `incl proc <#incl,CritBitTree[T],string,T>`_
  runnableExamples:
    var c: CritBitTree[void]
    incl(c, "key")
    doAssert c.hasKey("key")

  discard rawInsert(c, key)

proc incl*[T](c: var CritBitTree[T], key: string, val: T) =
  ## Inserts `key` with value `val` into `c`.
  ##
  ## See also:
  ## * `excl proc <#excl,CritBitTree[T],string>`_
  ## * `incl proc <#incl,CritBitTree[void],string>`_
  runnableExamples:
    var c: CritBitTree[int]
    incl(c, "key", 42)
    doAssert c["key"] == 42

  var n = rawInsert(c, key)
  n.val = val

proc `[]=`*[T](c: var CritBitTree[T], key: string, val: T) =
  ## Puts a (key, value)-pair into `t`.
  ##
  ## See also:
  ## * `[] proc <#[],CritBitTree[T],string>`_
  ## * `[] proc <#[],CritBitTree[T],string_2>`_
  runnableExamples:
    var c: CritBitTree[int]
    c["key"] = 42
    doAssert c["key"] == 42

  var n = rawInsert(c, key)
  n.val = val

template get[T](c: CritBitTree[T], key: string): T =
  let n = rawGet(c, key)
  if n == nil:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

  n.val

proc `[]`*[T](c: CritBitTree[T], key: string): T {.inline.} =
  ## Retrieves the value at ``c[key]``. If `key` is not in `t`, the
  ## ``KeyError`` exception is raised. One can check with ``hasKey`` whether
  ## the key exists.
  ##
  ## See also:
  ## * `[] proc <#[],CritBitTree[T],string_2>`_
  ## * `[]= proc <#[]=,CritBitTree[T],string,T>`_
  get(c, key)

proc `[]`*[T](c: var CritBitTree[T], key: string): var T {.inline.} =
  ## Retrieves the value at ``c[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``KeyError`` exception is raised.
  ##
  ## See also:
  ## * `[] proc <#[],CritBitTree[T],string>`_
  ## * `[]= proc <#[]=,CritBitTree[T],string,T>`_
  get(c, key)

iterator leaves[T](n: Node[T]): Node[T] =
  if n != nil:
    # XXX actually we could compute the necessary stack size in advance:
    # it's roughly log2(c.count).
    var stack = @[n]
    while stack.len > 0:
      var it = stack.pop
      while not it.isLeaf:
        stack.add(it.child[1])
        it = it.child[0]
        assert(it != nil)
      yield it

iterator keys*[T](c: CritBitTree[T]): string =
  ## Yields all keys in lexicographical order.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 1
    c["key2"] = 2
    var keys: seq[string]
    for key in c.keys:
      keys.add(key)
    doAssert keys == @["key1", "key2"]

  for x in leaves(c.root): yield x.key

iterator values*[T](c: CritBitTree[T]): T =
  ## Yields all values of `c` in the lexicographical order of the
  ## corresponding keys.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 1
    c["key2"] = 2
    var vals: seq[int]
    for val in c.values:
      vals.add(val)
    doAssert vals == @[1, 2]

  for x in leaves(c.root): yield x.val

iterator mvalues*[T](c: var CritBitTree[T]): var T =
  ## Yields all values of `c` in the lexicographical order of the
  ## corresponding keys. The values can be modified.
  ##
  ## See also:
  ## * `values iterator <#values.i,CritBitTree[T]>`_
  for x in leaves(c.root): yield x.val

iterator items*[T](c: CritBitTree[T]): string =
  ## Yields all keys in lexicographical order.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 1
    c["key2"] = 2
    var keys: seq[string]
    for key in c.items:
      keys.add(key)
    doAssert keys == @["key1", "key2"]

  for x in leaves(c.root): yield x.key

iterator pairs*[T](c: CritBitTree[T]): tuple[key: string, val: T] =
  ## Yields all (key, value)-pairs of `c`.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 1
    c["key2"] = 2
    var ps: seq[tuple[key: string, val: int]]
    for p in c.pairs:
      ps.add(p)
    doAssert ps == @[(key: "key1", val: 1), (key: "key2", val: 2)]

  for x in leaves(c.root): yield (x.key, x.val)

iterator mpairs*[T](c: var CritBitTree[T]): tuple[key: string, val: var T] =
  ## Yields all (key, value)-pairs of `c`. The yielded values can be modified.
  ##
  ## See also:
  ## * `pairs iterator <#pairs.i,CritBitTree[T]>`_
  for x in leaves(c.root): yield (x.key, x.val)

proc allprefixedAux[T](c: CritBitTree[T], key: string;
                       longestMatch: bool): Node[T] =
  var p = c.root
  var top = p
  if p != nil:
    while not p.isLeaf:
      var q = p
      let ch = if p.byte < key.len: key[p.byte] else: '\0'
      let dir = (1 + (ch.ord or p.otherBits.ord)) shr 8
      p = p.child[dir]
      if q.byte < key.len: top = p
    if not longestMatch:
      for i in 0 ..< key.len:
        if i >= p.key.len or p.key[i] != key[i]: return
    result = top

iterator itemsWithPrefix*[T](c: CritBitTree[T], prefix: string;
                             longestMatch = false): string =
  ## Yields all keys starting with `prefix`. If `longestMatch` is true,
  ## the longest match is returned, it doesn't have to be a complete match then.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 42
    c["key2"] = 43
    var keys: seq[string]
    for key in c.itemsWithPrefix("key"):
      keys.add(key)
    doAssert keys == @["key1", "key2"]

  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield x.key

iterator keysWithPrefix*[T](c: CritBitTree[T], prefix: string;
                            longestMatch = false): string =
  ## Yields all keys starting with `prefix`.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 42
    c["key2"] = 43
    var keys: seq[string]
    for key in c.keysWithPrefix("key"):
      keys.add(key)
    doAssert keys == @["key1", "key2"]

  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield x.key

iterator valuesWithPrefix*[T](c: CritBitTree[T], prefix: string;
                              longestMatch = false): T =
  ## Yields all values of `c` starting with `prefix` of the
  ## corresponding keys.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 42
    c["key2"] = 43
    var vals: seq[int]
    for val in c.valuesWithPrefix("key"):
      vals.add(val)
    doAssert vals == @[42, 43]

  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield x.val

iterator mvaluesWithPrefix*[T](c: var CritBitTree[T], prefix: string;
                               longestMatch = false): var T =
  ## Yields all values of `c` starting with `prefix` of the
  ## corresponding keys. The values can be modified.
  ##
  ## See also:
  ## * `valuesWithPrefix iterator <#valuesWithPrefix.i,CritBitTree[T],string>`_
  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield x.val

iterator pairsWithPrefix*[T](c: CritBitTree[T],
                             prefix: string;
                             longestMatch = false): tuple[key: string, val: T] =
  ## Yields all (key, value)-pairs of `c` starting with `prefix`.
  runnableExamples:
    var c: CritBitTree[int]
    c["key1"] = 42
    c["key2"] = 43
    var ps: seq[tuple[key: string, val: int]]
    for p in c.pairsWithPrefix("key"):
      ps.add(p)
    doAssert ps == @[(key: "key1", val: 42), (key: "key2", val: 43)]

  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield (x.key, x.val)

iterator mpairsWithPrefix*[T](c: var CritBitTree[T],
                              prefix: string;
                             longestMatch = false): tuple[key: string, val: var T] =
  ## Yields all (key, value)-pairs of `c` starting with `prefix`.
  ## The yielded values can be modified.
  ##
  ## See also:
  ## * `pairsWithPrefix iterator <#pairsWithPrefix.i,CritBitTree[T],string>`_
  let top = allprefixedAux(c, prefix, longestMatch)
  for x in leaves(top): yield (x.key, x.val)

proc `$`*[T](c: CritBitTree[T]): string =
  ## Turns `c` into a string representation. Example outputs:
  ## ``{keyA: value, keyB: value}``, ``{:}``
  ## If `T` is void the outputs look like:
  ## ``{keyA, keyB}``, ``{}``.
  if c.len == 0:
    when T is void:
      result = "{}"
    else:
      result = "{:}"
  else:
    # an educated guess is better than nothing:
    when T is void:
      const avgItemLen = 8
    else:
      const avgItemLen = 16
    result = newStringOfCap(c.count * avgItemLen)
    result.add("{")
    when T is void:
      for key in keys(c):
        if result.len > 1: result.add(", ")
        result.addQuoted(key)
    else:
      for key, val in pairs(c):
        if result.len > 1: result.add(", ")
        result.addQuoted(key)
        result.add(": ")
        result.addQuoted(val)
    result.add("}")

proc commonPrefixLen*[T](c: CritBitTree[T]): int {.inline, since((1, 3)).} =
  ## Returns longest common prefix length of all keys of `c`.
  ## If `c` is empty, returns 0.
  runnableExamples:
    var c: CritBitTree[void]
    doAssert c.commonPrefixLen == 0
    incl(c, "key1")
    doAssert c.commonPrefixLen == 4
    incl(c, "key2")
    doAssert c.commonPrefixLen == 3

  if c.root != nil:
    if c.root.isLeaf: len(c.root.key)
    else: c.root.byte
  else: 0


runnableExamples:
  static:
    block:
      var critbitAsSet: CritBitTree[void]
      doAssert critbitAsSet.len == 0
      incl critbitAsSet, "kitten"
      doAssert critbitAsSet.len == 1
      incl critbitAsSet, "puppy"
      doAssert critbitAsSet.len == 2
      incl critbitAsSet, "kitten"
      doAssert critbitAsSet.len == 2
      incl critbitAsSet, ""
      doAssert critbitAsSet.len == 3
  block:
    var critbitAsDict: CritBitTree[int]
    critbitAsDict["key"] = 42
    doAssert critbitAsDict["key"] == 42
    critbitAsDict["key"] = 0
    doAssert critbitAsDict["key"] == 0
    critbitAsDict["key"] = -int.high
    doAssert critbitAsDict["key"] == -int.high
    critbitAsDict["key"] = int.high
    doAssert critbitAsDict["key"] == int.high


when isMainModule:
  import sequtils

  var r: CritBitTree[void]
  r.incl "abc"
  r.incl "xyz"
  r.incl "def"
  r.incl "definition"
  r.incl "prefix"
  r.incl "foo"

  doAssert r.contains"def"

  r.excl "def"
  assert r.missingOrExcl("foo") == false
  assert "foo" notin toSeq(r.items)

  assert r.missingOrExcl("foo") == true

  assert toSeq(r.items) == @["abc", "definition", "prefix", "xyz"]

  assert toSeq(r.itemsWithPrefix("de")) == @["definition"]
  var c = CritBitTree[int]()

  c.inc("a")
  assert c["a"] == 1

  c.inc("a", 4)
  assert c["a"] == 5

  c.inc("a", -5)
  assert c["a"] == 0

  c.inc("b", 2)
  assert c["b"] == 2

  c.inc("c", 3)
  assert c["c"] == 3

  c.inc("a", 1)
  assert c["a"] == 1

  var cf = CritBitTree[float]()

  cf.incl("a", 1.0)
  assert cf["a"] == 1.0

  cf.incl("b", 2.0)
  assert cf["b"] == 2.0

  cf.incl("c", 3.0)
  assert cf["c"] == 3.0

  assert cf.len == 3
  cf.excl("c")
  assert cf.len == 2

  var cb: CritBitTree[string]
  cb.incl("help", "help")
  for k in cb.keysWithPrefix("helpp"):
    doAssert false, "there is no prefix helpp"
