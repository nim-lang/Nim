#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# not really an AVL tree anymore, but still balanced ...

template isBottom(n: PAvlNode): bool = n.link[0] == n

proc lowGauge(n: PAvlNode): int =
  var it = n
  while not isBottom(it):
    result = it.key
    it = it.link[0]

proc highGauge(n: PAvlNode): int =
  result = -1
  var it = n
  while not isBottom(it):
    result = it.upperBound
    it = it.link[1]

proc find(root: PAvlNode, key: int): PAvlNode =
  var it = root
  while not isBottom(it):
    if it.key == key: return it
    it = it.link[ord(it.key <% key)]

proc inRange(root: PAvlNode, key: int): PAvlNode =
  var it = root
  while not isBottom(it):
    if it.key <=% key and key <% it.upperBound: return it
    it = it.link[ord(it.key <% key)]

proc skew(t: var PAvlNode) =
  if t.link[0].level == t.level:
    var temp = t
    t = t.link[0]
    temp.link[0] = t.link[1]
    t.link[1] = temp

proc split(t: var PAvlNode) =
  if t.link[1].link[1].level == t.level:
    var temp = t
    t = t.link[1]
    temp.link[1] = t.link[0]
    t.link[0] = temp
    inc t.level

proc add(a: var MemRegion, t: var PAvlNode, key, upperBound: int) {.benign.} =
  if t.isBottom:
    t = allocAvlNode(a, key, upperBound)
  else:
    if key <% t.key:
      when defined(avlcorruption):
        if t.link[0] == nil:
          cprintf("bug here %p\n", t)
      add(a, t.link[0], key, upperBound)
    elif key >% t.key:
      when defined(avlcorruption):
        if t.link[1] == nil:
          cprintf("bug here B %p\n", t)
      add(a, t.link[1], key, upperBound)
    else:
      sysAssert false, "key already exists"
    skew(t)
    split(t)

proc del(a: var MemRegion, t: var PAvlNode, x: int) {.benign.} =
  if isBottom(t): return
  a.last = t
  if x <% t.key:
    del(a, t.link[0], x)
  else:
    a.deleted = t
    del(a, t.link[1], x)
  if t == a.last and not isBottom(a.deleted) and x == a.deleted.key:
    a.deleted.key = t.key
    a.deleted.upperBound = t.upperBound
    a.deleted = getBottom(a)
    t = t.link[1]
    deallocAvlNode(a, a.last)
  elif t.link[0].level < t.level-1 or
       t.link[1].level < t.level-1:
    dec t.level
    if t.link[1].level > t.level:
      t.link[1].level = t.level
    skew(t)
    skew(t.link[1])
    skew(t.link[1].link[1])
    split(t)
    split(t.link[1])

