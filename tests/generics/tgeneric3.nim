discard """
output: '''
312
1000000
1000000
500000
0
'''
"""

import strutils

type
  PNode[T,D] = ref TNode[T,D]
  TItem {.acyclic, pure, final, shallow.} [T,D] = object
        key: T
        value: D
        node: PNode[T,D]
        when not (D is string):
          val_set: bool

  TItems[T,D] = seq[ref TItem[T,D]]
  TNode {.acyclic, pure, final, shallow.} [T,D] = object
        slots: TItems[T,D]
        left: PNode[T,D]
        count: int32


  RPath[T,D] = tuple[
    Xi: int,
    Nd: PNode[T,D] ]

const
  cLen1 = 2
  cLen2 = 16
  cLen3 = 32
  cLenCenter = 80
  clen4 = 96
  cLenMax = 128
  cCenter = cLenMax div 2

proc len[T,D] (n:PNode[T,D]): int {.inline.} =
  return n.count

proc clean[T: SomeOrdinal|SomeNumber](o: var T) {.inline.} = discard

proc clean[T: string|seq](o: var T) {.inline.} =
  o = nil

proc clean[T,D] (o: ref TItem[T,D]) {.inline.} =
  when (D is string) :
    o.value = nil
  else :
    o.val_set = false

proc isClean[T,D] (it: ref TItem[T,D]): bool {.inline.} =
  when (D is string) :
    return it.value == nil
  else :
    return not it.val_set

proc isClean[T,D](n: PNode[T,D], x: int): bool {.inline.} =
  when (D is string):
    return n.slots[x].value == nil
  else:
    return not n.slots[x].val_set

proc setItem[T,D](Akey: T, Avalue: D, ANode: PNode[T,D]): ref TItem[T,D] {.inline.} =
  new(result)
  result.key = Akey
  result.value = Avalue
  result.node = ANode
  when not (D is string) :
    result.val_set = true

proc cmp[T:int8|int16|int32|int64|int] (a,b: T): T {.inline.} =
  return a-b

template binSearchImpl *(docmp: untyped) =
  var bFound = false
  result = 0
  var H = haystack.len - 1
  while result <= H :
    var I {.inject.} = (result + H) shr 1
    var SW = docmp
    if SW < 0: result = I + 1
    else:
      H = I - 1
      if SW == 0 : bFound = true
  if bFound: inc(result)
  else: result = - result

proc bSearch[T,D] (haystack: PNode[T,D], needle:T): int {.inline.} =
  binSearchImpl(haystack.slots[I].key.cmp(needle))

proc DeleteItem[T,D] (n: PNode[T,D], x: int): PNode[T,D] {.inline.} =
  var w = n.slots[x]
  if w.node != nil :
    clean(w)
    return n
  dec(n.count)
  if n.count > 0 :
    for i in countup(x, n.count - 1) : n.slots[i] = n.slots[i + 1]
    n.slots[n.count] = nil
    case n.count
    of cLen1 : setLen(n.slots, cLen1)
    of cLen2 : setLen(n.slots, cLen2)
    of cLen3 : setLen(n.slots, cLen3)
    of cLenCenter : setLen(n.slots, cLenCenter)
    of cLen4 : setLen(n.slots, cLen4)
    else: discard
    result = n

  else :
    result = n.left
    n.slots = @[]
    n.left = nil

proc internalDelete[T,D] (ANode: PNode[T,D], key: T, Avalue: var D): PNode[T,D] =
  var Path: array[0..20, RPath[T,D]]
  var n = ANode
  result = n
  clean(Avalue)
  var h = 0
  while n != nil:
    var x = bSearch(n, key)
    if x <= 0 :
      Path[h].Nd = n
      Path[h].Xi = - x
      inc(h)
      if x == 0 :
        n = n.left
      else :
        x = (-x) - 1
        if x < n.count :
          n = n.slots[x].node
        else :
          n = nil
    else :
      dec(x)
      if isClean(n, x) : return
      Avalue = n.slots[x].value
      var n2 = DeleteItem(n, x)
      dec(h)
      while (n2 != n) and (h >= 0) :
        n = n2
        var w = addr Path[h]
        x  = w.Xi - 1
        if x >= 0 :
          if (n == nil) and isClean(w.Nd, x) :
            n = w.Nd
            n.slots[x].node = nil
            n2 = DeleteItem(n, x)
          else :
            w.Nd.slots[x].node = n
            return
        else :
          w.Nd.left = n
          return
        dec(h)
      if h < 0:
        result = n2
      return

proc internalFind[T,D] (n: PNode[T,D], key: T): ref TItem[T,D] {.inline.} =
  var wn = n
  while wn != nil :
    var x = bSearch(wn, key)
    if x <= 0 :
      if x == 0 :
        wn = wn.left
      else :
        x = (-x) - 1
        if x < wn.count :
          wn = wn.slots[x].node
        else :
          return nil

    else :
      return wn.slots[x - 1]
  return nil

proc traceTree[T,D](root: PNode[T,D]) =
  proc traceX(x: int) =
    write stdout, "("
    write stdout, x
    write stdout, ") "

  proc traceEl(el: ref TItem[T,D]) =
    write stdout, " key: "
    write stdout, el.key
    write stdout, " value: "
    write stdout, el.value


  proc traceln(space: string) =
    writeLine stdout, ""
    write stdout, space

  proc doTrace(n: PNode[T,D], level: int) =
    var space = spaces(2 * level)
    traceln(space)
    write stdout, "node: "
    if n == nil:
      writeLine stdout, "is empty"
      return
    write stdout, n.count
    write stdout, " elements: "
    if n.left != nil:
      traceln(space)
      write stdout, "left: "
      doTrace(n.left, level+1)
    for i, el in n.slots:
      if el != nil and not isClean(el):
        traceln(space)
        traceX(i)
        if i >= n.count:
          write stdout, "error "
        else:
          traceEl(el)
          if el.node != nil: doTrace(el.node, level+1)
          else : write stdout, " empty "
      elif i < n.count :
        traceln(space)
        traceX(i)
        write stdout, "clean: "
        when T is string :
          if el.key != nil: write stdout, el.key
        else : write stdout, el.key
        if el.node != nil: doTrace(el.node, level+1)
        else : write stdout, " empty "
    writeLine stdout,""

  doTrace(root, 0)

proc InsertItem[T,D](APath: RPath[T,D], ANode:PNode[T,D], Akey: T, Avalue: D) =
  var x = - APath.Xi
  inc(APath.Nd.count)
  case APath.Nd.count
  of cLen1: setLen(APath.Nd.slots, cLen2)
  of cLen2: setLen(APath.Nd.slots, cLen3)
  of cLen3: setLen(APath.Nd.slots, cLenCenter)
  of cLenCenter: setLen(APath.Nd.slots, cLen4)
  of cLen4: setLen(APath.Nd.slots, cLenMax)
  else: discard
  for i in countdown(APath.Nd.count.int - 1, x + 1): shallowCopy(APath.Nd.slots[i], APath.Nd.slots[i - 1])
  APath.Nd.slots[x] = setItem(Akey, Avalue, ANode)


proc SplitPage[T,D](n, left: PNode[T,D], xi: int, Akey:var T, Avalue:var D): PNode[T,D] =
  var x = -xi
  var it1: TItems[T,D]
  it1.newSeq(cLenCenter)
  new(result)
  result.slots.newSeq(cLenCenter)
  result.count = cCenter
  if x == cCenter:
    for i in 0..cCenter-1: shallowCopy(it1[i], left.slots[i])
    for i in 0..cCenter-1: shallowCopy(result.slots[i], left.slots[cCenter + i])
    result.left = n
  else :
    if x < cCenter :
      for i in 0..x-1: shallowCopy(it1[i], left.slots[i])
      it1[x] = setItem(Akey, Avalue, n)
      for i in x+1 .. cCenter-1: shallowCopy(it1[i], left.slots[i-1])
      var w = left.slots[cCenter-1]
      Akey = w.key
      Avalue = w.value
      result.left = w.node
      for i in 0..cCenter-1: shallowCopy(result.slots[i], left.slots[cCenter + i])
    else :
      for i in 0..cCenter-1: shallowCopy(it1[i], left.slots[i])
      x = x - (cCenter + 1)
      for i in 0..x-1: shallowCopy(result.slots[i], left.slots[cCenter + i + 1])
      result.slots[x] = setItem(Akey, Avalue, n)
      for i in x+1 .. cCenter-1: shallowCopy(result.slots[i], left.slots[cCenter + i])
      var w = left.slots[cCenter]
      Akey = w.key
      Avalue = w.value
      result.left = w.node
  left.count = cCenter
  shallowCopy(left.slots, it1)


proc internalPut[T,D](ANode: ref TNode[T,D], Akey: T, Avalue: D, Oldvalue: var D): ref TNode[T,D] =
  var h: int
  var Path: array[0..30, RPath[T,D]]
  var left: PNode[T,D]
  var n = ANode


  result = ANode
  h = 0
  while n != nil:
    var x = bSearch[T,D](n, Akey)
    if x <= 0 :
      Path[h].Nd = n
      Path[h].Xi = x
      inc(h)
      if x == 0 :
        n = n.left
      else :
        x = (-x)-1
        if x < n.count :
          n = n.slots[x].node
        else :
          n = nil
    else :
      var w = n.slots[x - 1]
      Oldvalue = w.value
      w.value = Avalue
      return

  dec(h)
  left = nil
  var lkey = Akey
  var lvalue = Avalue
  while h >= 0 :
    if Path[h].Nd.count < cLenMax :
      InsertItem(Path[h], n, lkey, lvalue)
      return
    else :
      left = Path[h].Nd
      n = SplitPage(n, left, Path[h].Xi, lkey, lvalue)
    dec(h)

  new(result)
  result.slots.newSeq(cLen1)
  result.count = 1
  result.left = left
  result.slots[0] = setItem(lkey, lvalue, n)


proc CleanTree[T,D](n: PNode[T,D]): PNode[T,D] =
  if n.left != nil :
    n.left = CleanTree(n.left)
  for i in 0 .. n.count - 1 :
    var w = n.slots[i]
    if w.node != nil :
        w.node = CleanTree(w.node)
    clean(w.value)
    clean(w.key)
  n.slots = nil
  return nil


proc VisitAllNodes[T,D](n: PNode[T,D], visit: proc(n: PNode[T,D]): PNode[T,D] {.closure.} ): PNode[T,D] =
  if n != nil :
    if n.left != nil :
      n.left = VisitAllNodes(n.left, visit)
    for i in 0 .. n.count - 1 :
      var w = n.slots[i]
      if w.node != nil :
        w.node = VisitAllNodes(w.node, visit)
    return visit(n)
  return nil

proc VisitAllNodes[T,D](n: PNode[T,D], visit: proc(n: PNode[T,D]) {.closure.} ) =
  if n != nil:
    if n.left != nil :
      VisitAllNodes(n.left, visit)
    for i in 0 .. n.count - 1 :
      var w = n.slots[i]
      if w.node != nil :
        VisitAllNodes(w.node, visit)
    visit(n)

proc VisitAll[T,D](n: PNode[T,D], visit: proc(Akey: T, Avalue: D) {.closure.} ) =
  if n != nil:
    if n.left != nil :
      VisitAll(n.left, visit)
    for i in 0 .. n.count - 1 :
      var w = n.slots[i]
      if not w.isClean :
        visit(w.key, w.value)
      if w.node != nil :
        VisitAll(w.node, visit)

proc VisitAll[T,D](n: PNode[T,D], visit: proc(Akey: T, Avalue: var D):bool {.closure.} ): PNode[T,D] =
  if n != nil:
    var n1 = n.left
    if n1 != nil :
      var n2 = VisitAll(n1, visit)
      if n1 != n2 :
        n.left = n2
    var i = 0
    while i < n.count :
      var w = n.slots[i]
      if not w.isClean :
        if visit(w.key, w.value) :
          result = DeleteItem(n, i)
          if result == nil : return
          dec(i)
      n1 = w.node
      if n1 != nil :
        var n2 = VisitAll(n1, visit)
        if n1 != n2 :
          w.node = n2
      inc(i)
  return n

iterator keys* [T,D] (n: PNode[T,D]): T =
  if n != nil :
    var Path: array[0..20, RPath[T,D]]
    var level = 0
    var nd = n
    var i = -1
    while true :
      if i < nd.count :
        Path[level].Nd = nd
        Path[level].Xi = i
        if i < 0 :
          if nd.left != nil :
            nd = nd.left
            inc(level)
          else : inc(i)
        else :
          var w = nd.slots[i]
          if not w.isClean() :
            yield w.key
          if w.node != nil :
            nd = w.node
            i = -1
            inc(level)
          else : inc(i)
      else :
        dec(level)
        if level < 0 : break
        nd = Path[level].Nd
        i = Path[level].Xi
        inc(i)

proc test() =
  var oldvalue: int
  var root = internalPut[int, int](nil, 312, 312, oldvalue)
  var someOtherRoot = internalPut[string, int](nil, "312", 312, oldvalue)
  var it1 = internalFind(root, 312)
  echo it1.value

  for i in 1..1_000_000:
    root = internalPut(root, i, i, oldvalue)

  var cnt = 0
  oldvalue = -1
  when true : # code compiles, when this or the other when is switched to false
    for k in root.keys :
      if k <= oldvalue :
        echo k
      oldvalue = k
      inc(cnt)
    echo cnt
  when true :
    cnt = 0
    VisitAll(root, proc(key, val: int) = inc(cnt))
    echo cnt
    when true :
      root = VisitAll(root, proc(key: int, value: var int): bool =
        return key mod 2 == 0 )
    cnt = 0
    oldvalue = -1
    VisitAll(root, proc(key: int, value: int) {.closure.} =
      if key <= oldvalue :
        echo key
      oldvalue = key
      inc(cnt) )
    echo cnt
    root = VisitAll(root, proc(key: int, value: var int): bool =
      return key mod 2 != 0 )
    cnt = 0
    oldvalue = -1
    VisitAll(root, proc(key: int, value: int) {.closure.} =
      if key <= oldvalue :
        echo "error ", key
      oldvalue = key
      inc(cnt) )
    echo cnt
    #traceTree(root)

test()
