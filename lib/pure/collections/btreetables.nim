const
  # Minimal number of elements per node.
  # This should be a very small number, less than 10 for the most use cases.
  N = 10

type
  Entry[A, B] = object
    key: A
    val: B
    p: Node[A, B]

  Node[A, B] = ref object
    m: int  # number of elements
    p0: Node[A, B] # left-most pointer (nr. of pointers is always m+1)
    e: array[2*N, Entry[A, B]]

  CursorPosition[A, B] = tuple
    ## Index into the sorted table allowing access to either the key or the value.
    node: Node[A, B]
    entry: int

  Cursor[A, B] = seq[CursorPosition[A, B]]

  Table*[A, B] = object
    ## Generic sorted table, consisting of key-value pairs.
    ##
    ## `root` and `entries` are internal implementation details which cannot
    ## be directly accessed.
    ##
    ## For creating an empty Table, use `initTable proc<#initTable,int>`_.
    root: Node[A, B]
    entries: int # total number of entries in the tree

  TableRef*[A, B] = ref Table[A, B]  ## Ref version of `Table<#Table>`_.
    ##
    ## For creating a new empty TableRef, use `newTable proc
    ## <#newTable,int>`_.


template leq(a, b): bool = cmp(a, b) <= 0
template eq(a, b): bool = cmp(a, b) == 0

proc binarySearch[A, B](x: A; a: Node[A, B]): int {.inline.} =
  var
    l = 0
    r = a.m
    i: int
  while l < r:
    i = (l+r) div 2
    if leq(x, a.e[i].key):
      r = i
    else:
      l = i+1
  return r


proc initTable*[A, B](initialSize = 0): Table[A, B] =
  ## Creates a new empty Table.
  ##
  ## The `initialSize` parameter is there to be compatible with the
  ## hash table API, it has no effect on BTree tables.
  ##
  ## See also:
  ## * `toTable proc<#toTable,openArray[]>`_
  ## * `newTable proc<#newTable,int>`_ for creating a `TableRef`
  runnableExamples:
    let
      a = initTable[int, string]()
      b = initTable[char, seq[int]]()
  result = Table[A, B](root: Node[A, B](m: 0, p0: nil), entries: 0)


proc `[]=`*[A, B](t: var Table[A, B]; key: A; val: B)

proc toTable*[A, B](pairs: openArray[(A, B)]): Table[A, B] =
  ## Creates a new Table which contains the given `pairs`.
  ##
  ## `pairs` is a container consisting of `(key, value)` tuples.
  ##
  ## See also:
  ## * `initTable proc<#initTable,int>`_
  ## * `newTable proc<#newTable,openArray[]>`_ for a `TableRef` version
  runnableExamples:
    let a = [('a', 5), ('b', 9)]
    let b = toTable(a)
    assert b == {'a': 5, 'b': 9}.toTable

  result = initTable[A, B]()
  for key, val in items(pairs):
    result[key] = val


template getHelper(a, x, ifFound, ifNotFound) {.dirty.} =
  while true:
    var r = binarySearch(x, a)
    if (r < a.m) and eq(x, a.e[r].key):
      return ifFound
    a = if r == 0: a.p0 else: a.e[r-1].p
    if a.isNil:
      return ifNotFound


proc getOrDefault*[A, B](t: Table[A, B]; x: A): B =
  ## Retrieves the value at `t[key]` if `key` is in `t`.
  ## Otherwise, the default initialization value for type `B` is returned
  ## (e.g. 0 for any integer type).
  ##
  ## See also:
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,Table[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,Table[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toTable
    doAssert a.getOrDefault('a') == 5
    doAssert a.getOrDefault('z') == 0

  var a =
    if t.root.isNil: Node[A,B](m: 0, p0: nil)
    else: t.root
  getHelper(a, x, a.e[r].val, default(B))


proc getOrDefault*[A, B](t: Table[A, B];
                             x: A; default: B): B =
  ## Retrieves the value at `t[key]` if `key` is in `t`.
  ## Otherwise, `default` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,Table[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,Table[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toTable
    doAssert a.getOrDefault('a', 99) == 5
    doAssert a.getOrDefault('z', 99) == 99

  var a =
    if t.root.isNil: Node[A,B](m: 0, p0: nil)
    else: t.root
  getHelper(a, x, a.e[r].val, default)


proc `[]`*[A, B](t: Table[A, B]; x: A): B =
  ## Retrieves the value at `t[key]`.
  ##
  ## If `key` is not in `t`, the `KeyError` exception is raised.
  ## One can check with `hasKey proc<#hasKey,Table[A,B],A>`_ whether
  ## the key exists.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,Table[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_ for checking if a key is in
  ##   the table
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toTable
    doAssert a['a'] == 5
    doAssertRaises(KeyError):
      echo a['z']

  var a =
    if t.root.isNil: Node[A,B](m: 0, p0: nil)
    else: t.root
  while true:
    var r = binarySearch(x, a)
    if (r < a.m) and eq(x, a.e[r].key):
      return a.e[r].val
    a = if r == 0: a.p0 else: a.e[r-1].p
    if a.isNil:
      when compiles($key):
        raise newException(KeyError, "key not found: " & $key)
      else:
        raise newException(KeyError, "key not found")


proc `[]`*[A, B](t: var Table[A, B]; x: A): var B =
  ## Retrieves the value at `t[key]`. The value can be modified.
  ##
  ## If `key` is not in `t`, the `KeyError` exception is raised.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,Table[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_ for checking if a key is in
  ##   the table
  var a =
    if t.root.isNil: Node[A,B](m: 0, p0: nil)
    else: t.root
  while true:
    var r = binarySearch(x, a)
    if (r < a.m) and eq(x, a.e[r].key):
      return a.e[r].val
    a = if r == 0: a.p0 else: a.e[r-1].p
    if a.isNil:
      when compiles($key):
        raise newException(KeyError, "key not found: " & $key)
      else:
        raise newException(KeyError, "key not found")


proc hasKey*[A, B](t: Table[A, B]; x: A): bool =
  ## Returns true if `key` is in the table `t`.
  ##
  ## See also:
  ## * `contains proc<#contains,Table[A,B],A>`_ for use with the `in` operator
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  var a =
    if t.root.isNil: Node[A,B](m: 0, p0: nil)
    else: t.root
  getHelper(a, x, true, false)


proc contains*[A, B](t: Table[A, B]; x: A): bool =
  ## Alias of `hasKey proc<#hasKey,Table[A,B],A>`_ for use with
  ## the `in` operator.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toTable
    doAssert 'b' in a == true
    doAssert a.contains('z') == false

  return hasKey(t, x)


proc insertImpl[A, B](x: A; a: Node[A, B];
                      h: var bool; v: var Entry[A, B]): bool =
  # Search key x in B-tree with root a;
  # if found, change the value to the new one and return true.
  # Otherwise insert new item with key x.
  # If an entry is to be passed up, assign it to v.
  # h = "tree has become higher"

  result = true
  var u = v
  var r = binarySearch(x, a)

  if (r < a.m) and (a.e[r].key == x): # found
    a.e[r].val = v.val
    return false

  else: # item not on this page
    var b = if r == 0: a.p0 else: a.e[r-1].p

    if b.isNil: # not in tree, insert
      u.p = nil
      h = true
      u.key = x
    else:
      result = insertImpl(x, b, h, u)

    var i: int
    if h: # insert u to the left of a.e[r]
      if a.m < 2*N:
        h = false
        i = a.m
        while i > r:
          dec(i)
          a.e[i+1] = a.e[i]
        a.e[r] = u
        inc(a.m)
      else:
        new(b) # overflow; split a into a,b and assign the middle entry to v
        if r < N: # insert in left page a
          i = N-1
          v = a.e[i]
          while i > r:
            dec(i)
            a.e[i+1] = a.e[i]
          a.e[r] = u
          i = 0
          while i < N:
            b.e[i] = a.e[i+N]
            inc(i)
        else: # insert in right page b
          dec(r, N)
          i = 0
          if r == 0:
            v = u
          else:
            v = a.e[N]
            while i < r-1:
              b.e[i] = a.e[i+N+1]
              inc(i)
            b.e[i] = u
            inc(i)
          while i < N:
            b.e[i] = a.e[i+N]
            inc(i)
        a.m = N
        b.m = N
        b.p0 = v.p
        v.p = b


template insertHelper(t, key, val) =
  var u = Entry[A, B](key: key, val: val)
  var h = false
  var wasAdded = insertImpl(key, t.root, h, u)
  if wasAdded:
    inc(t.entries)
  if h: # the previous root had to be splitted, create a new one
    var q = t.root
    new(t.root)
    t.root.m = 1
    t.root.p0 = q
    t.root.e[0] = u


proc `[]=`*[A, B](t: var Table[A, B]; key: A; val: B) =
  ## Inserts a `(key, value)` pair into `t`.
  ##
  ## See also:
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `hasKeyOrPut proc<#hasKeyOrPut,Table[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,Table[A,B],A,B>`_
  ## * `del proc<#del,Table[A,B],A>`_ for removing a key from the table
  runnableExamples:
    var a = initTable[char, int]()
    a['x'] = 7
    a['y'] = 33
    doAssert a == {'x': 7, 'y': 33}.toTable

  if t.root.isNil: t = initTable[A, B]()
  insertHelper(t, key, val)


proc hasKeyOrPut*[A, B](t: var Table[A, B]; key: A; val: B): bool =
  ## Returns true if `key` is in the table, otherwise inserts `value`.
  ##
  ## See also:
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.toTable
    if a.hasKeyOrPut('a', 50):
      a['a'] = 99
    if a.hasKeyOrPut('z', 50):
      a['z'] = 99
    doAssert a == {'a': 99, 'b': 9, 'z': 50}.toTable

  if t.root.isNil: t = initTable[A, B]()
  if hasKey(t, key):
    result = true
  else:
    insertHelper(t, key, val)
    result = false

proc mgetOrPut*[A, B](t: var Table[A, B], key: A, val: B): var B =
  ## Retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  ##
  ## See also:
  ## * `[] proc<#[],Table[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,Table[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,Table[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,Table[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.toTable
    doAssert a.mgetOrPut('a', 99) == 5
    doAssert a.mgetOrPut('z', 99) == 99
    doAssert a == {'a': 5, 'b': 9, 'z': 99}.toTable

  # XXX: does this work correctly?
  if key notin t:
    t[key] = val
  return t[key]


proc underflowImpl[A, B](c, a: Node[A, B]; s: int; h: var bool) =
  # a = underflowing page,
  # c = ancestor page,
  # s = index of deleted entry in c
  var
    s = s
    b: Node[A, B]
    i, k: int

  if s < c.m: # b = page to the *right* of a
    b = c.e[s].p
    k = (b.m - N + 1) div 2 # k = number of surplus items available on page b
    a.e[N-1] = c.e[s]
    a.e[N-1].p = b.p0

    if k > 0: # balance by moving k-1 items from b to a
      while i < k-1:
        a.e[i+N] = b.e[i]
        inc(i)
      c.e[s] = b.e[k-1]
      b.p0 = c.e[s].p
      c.e[s].p = b
      dec(b.m, k)
      i = 0
      while i < b.m:
        b.e[i] = b.e[i+k]
        inc(i)
      a.m = N-1+k
      h = false
    else: # no surplus items in b: merge pages a and b, discard *b*
      i = 0
      while i < N:
        a.e[i+N] = b.e[i]
        inc(i)
      i = s
      dec(c.m)
      while i < c.m:
        c.e[i] = c.e[i+1]
        inc(i)
      a.m = 2*N
      h = c.m < N

  else: # b = page to the *left* of a
    dec(s)
    b = if s == 0: c.p0 else: c.e[s-1].p
    k = (b.m - N + 1) div 2 # k = number of surplus items available on page b

    if k > 0:
      i = N-1
      while i > 0:
        dec(i)
        a.e[i+k] = a.e[i]
      i = k-1
      a.e[i] = c.e[s]
      a.e[i].p = a.p0
      # move k-1 items from b to a, and one to c
      dec(b.m, k)
      while i > 0:
        dec(i)
        a.e[i] = b.e[i+b.m+1]
      c.e[s] = b.e[b.m]
      a.p0 = c.e[s].p
      c.e[s].p = a
      a.m = N-1 + k
      h = false
    else: # no surplus items in b: merge pages a and b, discard *a*
      c.e[s].p = a.p0
      b.e[N] = c.e[s]
      i = 0
      while i < N-1:
        b.e[i+N+1] = a.e[i]
        inc(i)
      b.m = 2*N
      dec(c.m)
      h = c.m < N



proc deleteImpl[A, B](x: A; a: Node[A, B]; h: var bool): bool =
  # search and delete key x in B-tree a;
  # if a page underflow arises, balance with adjacent page or merge;
  # h = "page a is undersize"
  if a.isNil: # if the key wasn't in the table
    return false

  result = true
  var r = binarySearch(x, a)
  var q = if r == 0: a.p0 else: a.e[r-1].p

  proc del[A, B](p, a: Node[A, B]; h: var bool) =
    var
      k: int
      q: Node[A, B]
    k = p.m-1
    q = p.e[k].p
    if q != nil:
      del(q, a, h)
      if h:
        underflowImpl(p, q, p.m, h)
    else:
      p.e[k].p = a.e[r].p
      a.e[r] = p.e[k]
      dec(p.m)
      h = p.m < N

  var i: int
  if (r < a.m) and (a.e[r].key == x): # found
    if q.isNil: # a is leaf page
      dec(a.m)
      h = a.m < N
      i = r
      while i < a.m:
        a.e[i] = a.e[i+1]
        inc(i)
    else:
      del(q, a, h)
      if h:
        underflowImpl(a, q, r, h)
  else:
    result = deleteImpl(x, q, h)
    if h:
      underflowImpl(a, q, r, h)


proc delHelper[A, B](t: var Table[A, B]; key: A) =
  var h = false
  var wasDeleted = deleteImpl(key, t.root, h)
  if wasDeleted:
    dec(t.entries)
  if h: # the previous root is gone, appoint a new one
    if t.root.m == 0:
      t.root = t.root.p0

proc del*[A, B](t: var Table[A, B]; key: A) =
  ## Deletes `key` from table `t`. Does nothing if the key does not exist.
  ##
  ## See also:
  ## * `pop proc<#pop,Table[A,B],A,B>`_
  ## * `clear proc<#clear,Table[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toTable
    a.del('a')
    doAssert a == {'b': 9, 'c': 13}.toTable
    a.del('z')
    doAssert a == {'b': 9, 'c': 13}.toTable

  if t.root.isNil: t = initTable[A, B]()
  delHelper(t, key)

proc pop*[A, B](t: var Table[A, B], key: A, val: var B): bool =
  ## Deletes the `key` from the table.
  ## Returns `true`, if the `key` existed, and sets `val` to the
  ## mapping of the key. Otherwise, returns `false`, and the `val` is
  ## unchanged.
  ##
  ## See also:
  ## * `del proc<#del,Table[A,B],A>`_
  ## * `clear proc<#clear,Table[A,B]>`_ to empty the whole table
  runnableExamples:
    var
      a = {'a': 5, 'b': 9, 'c': 13}.toTable
      i: int
    doAssert a.pop('b', i) == true
    doAssert a == {'a': 5, 'c': 13}.toTable
    doAssert i == 9
    i = 0
    doAssert a.pop('z', i) == false
    doAssert a == {'a': 5, 'c': 13}.toTable
    doAssert i == 0

  if t.root.isNil: t = initTable[A, B]()
  result = t.hasKey(key)
  if result:
    val = t[key]
    delHelper(t, key)

proc take*[A, B](t: var Table[A, B];
                     key: A; val: var B): bool =
  ## Alias for:
  ## * `pop proc<#pop,Table[A,B],A,B>`_
  pop(t, key, val)


proc clear*[A, B](t: var Table[A, B]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,Table[A,B],A>`_
  ## * `pop proc<#pop,Table[A,B],A,B>`_
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toTable
    doAssert len(a) == 3
    clear(a)
    doAssert len(a) == 0

  # XXX: can we simplify it like this?
  t = initTable[A, B]()

proc len*[A, B](t: Table[A, B]): int {.inline.} =
  ## Returns the number of keys in ``t``.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toTable
    doAssert len(a) == 2

  t.entries

proc key[A, B](position: CursorPosition[A, B]): A =
  ## Return the key for a given cursor position.
  position.node.e[position.entry].key

proc val[A, B](position: CursorPosition[A, B]): B =
  ## Return the value for a given cursor position.
  position.node.e[position.entry].val

proc mval[A, B](position: CursorPosition[A, B]): var B =
  ## Returns a reference to the value for a given cursor position.
  position.node.e[position.entry].val

proc search[A, B](b: Table[A, B], key: A): Cursor[A, B] =
  ## Calculates the cursor pointing to the given key.
  var a = b.root
  while not a.isNil:
    var r = binarySearch(key, a)
    if r < a.m:
      result.add((a, r))
      if eq(key, a.e[r].key):
        break
    a = if r == 0: a.p0 else: a.e[r-1].p
  # add a dummy entry for first next call
  result.add((nil, 0))

proc current[A, B](cursor: Cursor[A, B]): CursorPosition[A, B] =
  ## Returns the current position of a cursor.
  ## This call is only valid if cursor.next previously returned true.
  cursor[^1]

proc next[A, B](cursor: var Cursor[A, B]): bool =
  ## Moves the cursor forward returning true if cursor.current is now valid.
  ## Never call current after next returns false.
  var (node, oldEntry) = cursor.pop()
  if not node.isNil:
    var newEntry = oldEntry + 1
    if newEntry < node.m:
        cursor.add((node, newEntry))
    var child = node.e[oldEntry].p
    if not child.isNil:
      while not child.isNil:
        cursor.add((child, 0))
        child = child.p0
  return cursor.len > 0 and cursor.current.node.m > 0

proc cursorFromStart[A, B](b: Table[A, B]): Cursor[A, B] =
  result = @[]
  var a = b.root
  while not a.isNil:
    result.add((a, 0))
    a = a.p0
  result.add((nil, 0))

iterator entries[A, B](b: Table[A, B]): CursorPosition[A, B] =
  var cursor = b.cursorFromStart
  while cursor.next:
    yield cursor.current


iterator entriesFrom[A, B](b: Table[A, B], fromKey: A): CursorPosition[A, B] =
  # Iterates the sorted table from the given key to the end.
  var cursor = b.search(fromKey)
  while cursor.next:
    yield cursor.current

iterator entriesBetween[A, B](b: Table[A, B], fromKey: A, toKey: A): CursorPosition[A, B] =
  # Iterates the sorted table from fromKey to toKey inclusive.
  var cursor = b.search(fromKey)
  while cursor.next:
    let position = cursor.current
    if not leq(position.key, toKey):
      break
    yield position


iterator keys*[A, B](t: Table[A, B]): A =
  ## Iterates over all the keys in the table `t`.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,Table[A,B]>`_
  ## * `values iterator<#values.i,Table[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toTable
    for k in a.keys:
      a[k].add(99)
    doAssert a == {'e': @[2, 4, 6, 8, 99], 'o': @[1, 5, 7, 9, 99]}.toTable

  for e in entries(t):
    yield e.key

iterator keysFrom*[A, B](b: Table[A, B], fromKey: A): A =
  ## Iterates over keys in the table from `fromKey` to the end.
  for e in entriesFrom(b, fromKey):
    yield e.key

iterator keysBetween*[A, B](b: Table[A, B], fromKey: A, toKey: A): A =
  ## Iterates over keys in the table from `fromKey` to `toKey` inclusive.
  for e in entriesBetween(b, fromKey, toKey):
    yield e.key


iterator values*[A, B](t: Table[A, B]): B =
  ## Iterates over all the values in the table `t`.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,Table[A,B]>`_
  ## * `keys iterator<#keys.i,Table[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,Table[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toTable
    for v in a.values:
      doAssert v.len == 4

  for e in entries(t):
    yield e.val

iterator mvalues*[A, B](t: var Table[A, B]): var B =
  ## Iterates over all the values in the table `t`.
  ## The values can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,Table[A,B]>`_
  ## * `values iterator<#values.i,Table[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toTable
    for v in a.mvalues:
      v.add(99)
    doAssert a == {'e': @[2, 4, 6, 8, 99], 'o': @[1, 5, 7, 9, 99]}.toTable

  for e in entries(t):
    yield e.mval

iterator valuesFrom*[A, B](b: Table[A, B], fromKey: A): B =
  ## Iterates over the values in the table from the given key to the end.
  for e in entriesFrom(b, fromKey):
    yield e.val

iterator valuesBetween*[A, B](b: Table[A, B], fromKey: A, toKey: A): B =
  ## Iterates over the values in the table from `fromKey` to `toKey` inclusive.
  for e in entriesBetween(b, fromKey, toKey):
    yield e.val


iterator pairs*[A, B](t: Table[A, B]): (A, B) =
  ## Iterates over all `(key, value)` pairs in the table `t`.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,Table[A,B]>`_
  ## * `keys iterator<#keys.i,Table[A,B]>`_
  ## * `values iterator<#values.i,Table[A,B]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = {
  ##     'o': [1, 5, 7, 9],
  ##     'e': [2, 4, 6, 8]
  ##     }.toTable
  ##
  ##   for k, v in a.pairs:
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: e
  ##   # value: [2, 4, 6, 8]
  ##   # key: o
  ##   # value: [1, 5, 7, 9]
  for e in entries(t):
    yield (e.key, e.val)

iterator mpairs*[A, B](t: var Table[A, B]): (A, var B) =
  ## Iterates over all `(key, value)` pairs in the table `t`.
  ## The values can be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,Table[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,Table[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toTable
    for k, v in a.mpairs:
      v.add(v[0] + 10)
    doAssert a == {'e': @[2, 4, 6, 8, 12], 'o': @[1, 5, 7, 9, 11]}.toTable

  for e in entries(t):
    yield (e.key, e.mval)


iterator pairsFrom*[A, B](b: Table[A, B], fromKey: A): tuple[key: A, val: B] =
  ## Iterates over `(key, value)` pairs in the table from the given key to the end.
  for e in entriesFrom(b, fromKey):
    yield (e.key, e.val)

iterator pairsBetween*[A, B](b: Table[A, B], fromKey: A, toKey: A): tuple[key: A, val: B] =
  ## Iterates over `(key, value)` pairs in the table from `fromKey` to `toKey` inclusive.
  for e in entriesBetween(b, fromKey, toKey):
    yield (e.key, e.val)


proc `$`*[A, B](t: Table[A, B]): string =
  ## The ``$`` operator for tables. Used internally when calling `echo`
  ## on a table.
  if t.entries == 0:
    result = "{:}"
  else:
    result = "{"
    for (k, v) in pairs(t):
      if result.len > 1: result.add(", ")
      result.addQuoted(k)
      result.add(": ")
      result.addQuoted(v)
    result.add("}")

proc `==`*[A, B](a, b: Table[A, B]): bool =
  ## The `==` operator for Tables.
  ##
  ## Returns `true` if the content of both tables contains the same
  ## key-value pairs. Insert order does not matter.
  runnableExamples:
    let
      a = {'a': 5, 'b': 9, 'c': 13}.toTable
      b = {'b': 9, 'c': 13, 'a': 5}.toTable
    doAssert a == b

  if a.root.isNil and b.root.isNil:
    return true
  if a.entries == b.entries:
    for k, v in a:
      if not b.hasKey(k): return false
      if b.getOrDefault(k) != v: return false
    return true





# -------------------------------------------------------------------
# ---------------------------- TableRef -----------------------------
# -------------------------------------------------------------------


proc newTable*[A, B](): <//>TableRef[A, B] =
  ## Creates a new ref table that is empty.
  ##
  ## ``initialSize`` must be a power of two (default: 64).
  ## If you need to accept runtime values for this you could use the
  ## `nextPowerOfTwo proc<math.html#nextPowerOfTwo,int>`_ from the
  ## `math module<math.html>`_ or the `rightSize proc<#rightSize,Natural>`_
  ## from this module.
  ##
  ## See also:
  ## * `newTable proc<#newTable,openArray[]>`_ for creating a `TableRef`
  ##   from a collection of `(key, value)` pairs
  ## * `initTable proc<#initTable,int>`_ for creating a `Table`
  runnableExamples:
    let
      a = newTable[int, string]()
      b = newTable[char, seq[int]]()

  new(result)
  result[] = initTable[A, B]()

proc newTable*[A, B](pairs: openArray[(A, B)]): <//>TableRef[A, B] =
  ## Creates a new ref table that contains the given ``pairs``.
  ##
  ## ``pairs`` is a container consisting of ``(key, value)`` tuples.
  ##
  ## See also:
  ## * `newTable proc<#newTable,int>`_
  ## * `toTable proc<#toTable,openArray[]>`_ for a `Table` version
  runnableExamples:
    let a = [('a', 5), ('b', 9)]
    let b = newTable(a)
    assert b == {'a': 5, 'b': 9}.newTable

  new(result)
  result[] = toTable[A, B](pairs)

proc newTableFrom*[A, B, C](collection: A, index: proc(x: B): C): <//>TableRef[C, B] =
  ## Index the collection with the proc provided.
  # TODO: As soon as supported, change collection: A to collection: A[B]
  result = newTable[C, B]()
  for item in collection:
    result[index(item)] = item


proc `[]`*[A, B](t: TableRef[A, B], key: A): var B =
  ## Retrieves the value at ``t[key]``.
  ##
  ## If ``key`` is not in ``t``, the  ``KeyError`` exception is raised.
  ## One can check with `hasKey proc<#hasKey,TableRef[A,B],A>`_ whether
  ## the key exists.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,TableRef[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,TableRef[A,B],A>`_ for checking if a key is in
  ##   the table
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert a['a'] == 5
    doAssertRaises(KeyError):
      echo a['z']

  result = t[][key]

proc `[]=`*[A, B](t: TableRef[A, B], key: A, val: B) =
  ## Inserts a ``(key, value)`` pair into ``t``.
  ##
  ## See also:
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKeyOrPut proc<#hasKeyOrPut,TableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,TableRef[A,B],A,B>`_
  ## * `del proc<#del,TableRef[A,B],A>`_ for removing a key from the table
  runnableExamples:
    var a = newTable[char, int]()
    a['x'] = 7
    a['y'] = 33
    doAssert a == {'x': 7, 'y': 33}.newTable

  t[][key] = val

proc hasKey*[A, B](t: TableRef[A, B], key: A): bool =
  ## Returns true if ``key`` is in the table ``t``.
  ##
  ## See also:
  ## * `contains proc<#contains,TableRef[A,B],A>`_ for use with the `in`
  ##   operator
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert a.hasKey('a') == true
    doAssert a.hasKey('z') == false

  result = t[].hasKey(key)


proc contains*[A, B](t: TableRef[A, B], key: A): bool =
  ## Alias of `hasKey proc<#hasKey,TableRef[A,B],A>`_ for use with
  ## the ``in`` operator.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert 'b' in a == true
    doAssert a.contains('z') == false

  return hasKey[A, B](t, key)

proc hasKeyOrPut*[A, B](t: var TableRef[A, B], key: A, val: B): bool =
  ## Returns true if ``key`` is in the table, otherwise inserts ``value``.
  ##
  ## See also:
  ## * `hasKey proc<#hasKey,TableRef[A,B],A>`_
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.newTable
    if a.hasKeyOrPut('a', 50):
      a['a'] = 99
    if a.hasKeyOrPut('z', 50):
      a['z'] = 99
    doAssert a == {'a': 99, 'b': 9, 'z': 50}.newTable

  t[].hasKeyOrPut(key, val)

proc getOrDefault*[A, B](t: TableRef[A, B], key: A): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``. Otherwise, the
  ## default initialization value for type ``B`` is returned (e.g. 0 for any
  ## integer type).
  ##
  ## See also:
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,TableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,TableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,TableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert a.getOrDefault('a') == 5
    doAssert a.getOrDefault('z') == 0

  getOrDefault(t[], key)

proc getOrDefault*[A, B](t: TableRef[A, B], key: A, default: B): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``.
  ## Otherwise, ``default`` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,TableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,TableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,TableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert a.getOrDefault('a', 99) == 5
    doAssert a.getOrDefault('z', 99) == 99

  getOrDefault(t[], key, default)

proc mgetOrPut*[A, B](t: TableRef[A, B], key: A, val: B): var B =
  ## Retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  ##
  ## See also:
  ## * `[] proc<#[],TableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,TableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,TableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,TableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.newTable
    doAssert a.mgetOrPut('a', 99) == 5
    doAssert a.mgetOrPut('z', 99) == 99
    doAssert a == {'a': 5, 'b': 9, 'z': 99}.newTable

  t[].mgetOrPut(key, val)


proc len*[A, B](t: TableRef[A, B]): int =
  ## Returns the number of keys in ``t``.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newTable
    doAssert len(a) == 2

  result = t.entries


proc del*[A, B](t: TableRef[A, B], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## **If duplicate keys were added, this may need to be called multiple times.**
  ##
  ## See also:
  ## * `pop proc<#pop,TableRef[A,B],A,B>`_
  ## * `clear proc<#clear,TableRef[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.newTable
    a.del('a')
    doAssert a == {'b': 9, 'c': 13}.newTable
    a.del('z')
    doAssert a == {'b': 9, 'c': 13}.newTable

  t[].del(key)

proc pop*[A, B](t: TableRef[A, B], key: A, val: var B): bool =
  ## Deletes the ``key`` from the table.
  ## Returns ``true``, if the ``key`` existed, and sets ``val`` to the
  ## mapping of the key. Otherwise, returns ``false``, and the ``val`` is
  ## unchanged.
  ##
  ## **If duplicate keys were added, this may need to be called multiple times.**
  ##
  ## See also:
  ## * `del proc<#del,TableRef[A,B],A>`_
  ## * `clear proc<#clear,TableRef[A,B]>`_ to empty the whole table
  runnableExamples:
    var
      a = {'a': 5, 'b': 9, 'c': 13}.newTable
      i: int
    doAssert a.pop('b', i) == true
    doAssert a == {'a': 5, 'c': 13}.newTable
    doAssert i == 9
    i = 0
    doAssert a.pop('z', i) == false
    doAssert a == {'a': 5, 'c': 13}.newTable
    doAssert i == 0

  result = t[].pop(key, val)


proc take*[A, B](t: TableRef[A, B], key: A, val: var B): bool {.inline.} =
  ## Alias for:
  ## * `pop proc<#pop,TableRef[A,B],A,B>`_
  pop(t, key, val)


proc clear*[A, B](t: TableRef[A, B]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,Table[A,B],A>`_
  ## * `pop proc<#pop,Table[A,B],A,B>`_
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.newTable
    doAssert len(a) == 3
    clear(a)
    doAssert len(a) == 0

  # XXX: can we simplify it like this?
  t[] = initTable[A, B]()

proc `$`*[A, B](t: TableRef[A, B]): string =
  ## The ``$`` operator for tables. Used internally when calling `echo`
  ## on a table.
  `$`(t[])


proc `==`*[A, B](s, t: TableRef[A, B]): bool =
  ## The ``==`` operator for tables. Returns ``true`` if either both tables
  ## are ``nil``, or neither is ``nil`` and the content of both tables contains the
  ## same key-value pairs. Insert order does not matter.
  runnableExamples:
    let
      a = {'a': 5, 'b': 9, 'c': 13}.newTable
      b = {'b': 9, 'c': 13, 'a': 5}.newTable
    doAssert a == b

  if isNil(s): result = isNil(t)
  elif isNil(t): result = false
  else: result = s[] == t[]


iterator keys*[A, B](t: TableRef[A, B]): A =
  ## Iterates over any key in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,TableRef[A,B]>`_
  ## * `values iterator<#values.i,TableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newTable
    for k in a.keys:
      a[k].add(99)
    doAssert a == {'e': @[2, 4, 6, 8, 99], 'o': @[1, 5, 7, 9, 99]}.newTable

  for k in keys(t[]):
    yield k

iterator values*[A, B](t: TableRef[A, B]): B =
  ## Iterates over any value in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,TableRef[A,B]>`_
  ## * `keys iterator<#keys.i,TableRef[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,TableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newTable
    for v in a.values:
      doAssert v.len == 4

  for v in values(t[]):
    yield v

iterator mvalues*[A, B](t: TableRef[A, B]): var B =
  ## Iterates over any value in the table ``t``. The values can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,TableRef[A,B]>`_
  ## * `values iterator<#values.i,TableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newTable
    for v in a.mvalues:
      v.add(99)
    doAssert a == {'e': @[2, 4, 6, 8, 99], 'o': @[1, 5, 7, 9, 99]}.newTable

  for v in mvalues(t[]):
    yield v

iterator pairs*[A, B](t: TableRef[A, B]): (A, B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t``.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,TableRef[A,B]>`_
  ## * `keys iterator<#keys.i,TableRef[A,B]>`_
  ## * `values iterator<#values.i,TableRef[A,B]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = {
  ##     'o': [1, 5, 7, 9],
  ##     'e': [2, 4, 6, 8]
  ##     }.newTable
  ##
  ##   for k, v in a.pairs:
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: e
  ##   # value: [2, 4, 6, 8]
  ##   # key: o
  ##   # value: [1, 5, 7, 9]
  for p in pairs(t[]):
    yield p

iterator mpairs*[A, B](t: TableRef[A, B]): (A, var B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t``. The values
  ## can be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,TableRef[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,TableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newTable
    for k, v in a.mpairs:
      v.add(v[0] + 10)
    doAssert a == {'e': @[2, 4, 6, 8, 12], 'o': @[1, 5, 7, 9, 11]}.newTable

  for (k, v) in mpairs(t[]):
    yield (k, v)





# ---------------------------------------------------------------------------
# ------------------------------ OrderedTable -------------------------------
# ---------------------------------------------------------------------------



const SmallLimit = 2 # XXX: small for testing purposes, should be a bit higher

type
  OrderedTable*[A, B] = object
    ## Table that remembers insertion order.
    ##
    ## For creating an empty OrderedTable, use `initOrderedTable proc
    ## <#initOrderedTable,int>`_.
    data: seq[(A, B)]
    byKey: Table[A, int] # int --> position of data

  OrderedTableRef*[A, B] = ref OrderedTable[A, B] ## Ref version of
    ## `OrderedTable<#OrderedTable>`_.
    ##
    ## For creating a new empty OrderedTableRef, use `newOrderedTable proc
    ## <#newOrderedTable,int>`_.


template isSmall(t): untyped =
  t.data.len < SmallLimit and t.byKey.len == 0


proc findInData[A, B](data: seq[(A, B)]; k: A): int =
  for i in 0 ..< data.len:
    if data[i][0] == k: return i
  return -1

proc populateByKey[A, B](t: var OrderedTable[A, B]) =
  for i in 0 ..< t.data.len:
    var k = t.data[i][0]
    t.byKey[k] = i

proc putImpl[A, B](t: var OrderedTable[A, B]; k: A; v: B) =
  var keyIndex: int
  if isSmall(t):
    keyIndex = findInData(t.data, k)
    if keyIndex < 0:
      t.data.add((k, v))
      if t.data.len == Smalllimit:
        populateByKey(t)
    else:
      t.data[keyIndex] = (k, v)
  else:
    keyIndex = getOrDefault(t.byKey, k, -1)
    if keyIndex < 0:
      t.data.add((k, v))
      t.byKey[k] = t.data.high
    else:
      t.data[keyIndex] = (k, v)
      t.byKey[k] = keyIndex

template get(t, key): untyped =
  if isSmall(t):
    for i in 0 ..< t.data.len:
      if t.data[i][0] == key:
        return t.data[i][1]
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")
  else:
    var keyIndex = t.byKey[key] # this will raise an exception if not found
    return (t.data[keyIndex])[1]


proc initOrderedTable*[A, B](initialSize = 64): OrderedTable[A, B] =
  ## Creates a new ordered table that is empty.
  ##
  ## Starting from Nim v0.20, tables are initialized by default and it is
  ## not necessary to call this function explicitly.
  ##
  ## See also:
  ## * `toOrderedTable proc<#toOrderedTable,openArray[]>`_
  ## * `newOrderedTable proc<#newOrderedTable,int>`_ for creating an
  ##   `OrderedTableRef`
  runnableExamples:
    let
      a = initOrderedTable[int, string]()
      b = initOrderedTable[char, seq[int]]()
  result = OrderedTable[A, B](data: newSeqOfCap[(A, B)](initialSize),
                              byKey: initTable[A, int]())

proc `[]=`*[A, B](t: var OrderedTable[A, B]; k: A; v: B) =
  ## Inserts a ``(key, value)`` pair into ``t``.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTable[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTable[A,B],A,B>`_
  ## * `del proc<#del,OrderedTable[A,B],A>`_ for removing a key from the table
  runnableExamples:
    var a = initOrderedTable[char, int]()
    a['x'] = 7
    a['y'] = 33
    doAssert a == {'x': 7, 'y': 33}.toOrderedTable

  putImpl(t, k, v)


proc toOrderedTable*[A, B](pairs: openArray[(A, B)]): OrderedTable[A, B] =
  ## Creates a new ordered table that contains the given ``pairs``.
  ##
  ## ``pairs`` is a container consisting of ``(key, value)`` tuples.
  ##
  ## See also:
  ## * `initOrderedTable proc<#initOrderedTable,int>`_
  ## * `newOrderedTable proc<#newOrderedTable,openArray[]>`_ for an
  ##   `OrderedTableRef` version
  runnableExamples:
    let a = [('a', 5), ('b', 9)]
    let b = toOrderedTable(a)
    assert b == {'a': 5, 'b': 9}.toOrderedTable

  for (key, val) in items(pairs):
    result[key] = val

proc `[]`*[A, B](t: OrderedTable[A, B], key: A): B =
  ## Retrieves the value at ``t[key]``.
  ##
  ## If ``key`` is not in ``t``, the  ``KeyError`` exception is raised.
  ## One can check with `hasKey proc<#hasKey,OrderedTable[A,B],A>`_ whether
  ## the key exists.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,OrderedTable[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_ for checking if a
  ##   key is in the table
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert a['a'] == 5
    doAssertRaises(KeyError):
      echo a['z']

  get(t, key)

proc `[]`*[A, B](t: var OrderedTable[A, B], key: A): var B =
  ## Retrieves the value at ``t[key]``. The value can be modified.
  ##
  ## If ``key`` is not in ``t``, the ``KeyError`` exception is raised.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,OrderedTable[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_ for checking if a
  ##   key is in the table
  get(t, key)

proc hasKey*[A, B](t: OrderedTable[A, B], key: A): bool =
  ## Returns true if ``key`` is in the table ``t``.
  ##
  ## See also:
  ## * `contains proc<#contains,OrderedTable[A,B],A>`_ for use with the `in`
  ##   operator
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert a.hasKey('a') == true
    doAssert a.hasKey('z') == false

  if isSmall(t):
    for (k, _) in t.data:
      if k == key:
        return true
  else:
    return key in t.byKey

proc contains*[A, B](t: OrderedTable[A, B], key: A): bool =
  ## Alias of `hasKey proc<#hasKey,OrderedTable[A,B],A>`_ for use with
  ## the ``in`` operator.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert 'b' in a == true
    doAssert a.contains('z') == false

  return hasKey[A, B](t, key)

proc hasKeyOrPut*[A, B](t: var OrderedTable[A, B], key: A, val: B): bool =
  ## Returns true if ``key`` is in the table, otherwise inserts ``value``.
  ##
  ## See also:
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.toOrderedTable
    if a.hasKeyOrPut('a', 50):
      a['a'] = 99
    if a.hasKeyOrPut('z', 50):
      a['z'] = 99
    doAssert a == {'a': 99, 'b': 9, 'z': 50}.toOrderedTable

  result = key in t
  if not result:
    t[key] = val

proc getOrDefault*[A, B](t: OrderedTable[A, B], key: A): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``. Otherwise, the
  ## default initialization value for type ``B`` is returned (e.g. 0 for any
  ## integer type).
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTable[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTable[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert a.getOrDefault('a') == 5
    doAssert a.getOrDefault('z') == 0

  if key in t:
    return t[key]
  else:
    return default(B)

proc getOrDefault*[A, B](t: OrderedTable[A, B], key: A, default: B): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``.
  ## Otherwise, ``default`` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTable[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTable[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert a.getOrDefault('a', 99) == 5
    doAssert a.getOrDefault('z', 99) == 99

  if key in t:
    return t[key]
  else:
    return default

proc mgetOrPut*[A, B](t: var OrderedTable[A, B], key: A, val: B): var B =
  ## Retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTable[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTable[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTable[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTable[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert a.mgetOrPut('a', 99) == 5
    doAssert a.mgetOrPut('z', 99) == 99
    doAssert a == {'a': 5, 'b': 9, 'z': 99}.toOrderedTable

  # XXX: does this work correctly?
  if key notin t:
    t[key] = val
  return t[key]

proc len*[A, B](t: OrderedTable[A, B]): int {.inline.} =
  ## Returns the number of keys in ``t``.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.toOrderedTable
    doAssert len(a) == 2

  result = t.data.len

proc add*[A, B](t: var OrderedTable[A, B], key: A, val: B) =
  raise newException(Exception, "this function is not available when using BTree-based Tables")

proc del*[A, B](t: var OrderedTable[A, B], key: A) =
  ## Deletes ``key`` from table ``t``.
  ## Does nothing if the key does not exist.
  ##
  ## **NOTE**: This proc is destructive: the original order of the elements
  ## is not preserved!
  ##
  ## If you want to keep the order of elements after removal,
  ## use `delete proc<#delete,OrderedTable[A,B],A>`_.
  ##
  ## See also:
  ## * `delete proc<#delete,OrderedTable[A,B],A>`_
  ## * `pop proc<#pop,OrderedTable[A,B],A,B>`_
  ## * `clear proc<#clear,OrderedTable[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toOrderedTable
    a.del('a')
    doAssert a == {'c': 13, 'b': 9}.toOrderedTable
    a.del('z')
    doAssert a == {'c': 13, 'b': 9}.toOrderedTable

  var keyIndex = -1
  if isSmall(t):
    for i, (k, _) in t.data:
      if k == key:
        keyIndex = i
    if keyIndex >= 0:
      t.data.del(keyIndex)
  else:
    keyIndex = t.byKey.getOrDefault(key, -1)
    if keyIndex >= 0:
      t.data.del(keyIndex)
      t.byKey.del(key)
      if keyIndex < t.data.len: # it wasn't the last element
        var newKey = t.data[keyIndex][0]
        t.byKey[newKey] = keyIndex

proc delete*[A, B](t: var OrderedTable[A, B], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTable[A,B],A>`_ for faster version which doesn't
  ##   preserve the order
  ## * `pop proc<#pop,OrderedTable[A,B],A,B>`_
  ## * `clear proc<#clear,OrderedTable[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toOrderedTable
    a.delete('a')
    doAssert a == {'b': 9, 'c': 13}.toOrderedTable
    a.delete('z')
    doAssert a == {'b': 9, 'c': 13}.toOrderedTable

  var keyIndex = -1
  if isSmall(t):
    for i, (k, _) in t.data:
      if k == key:
        keyIndex = i
    if keyIndex >= 0:
      t.data.delete(keyIndex)
  else:
    keyIndex = t.byKey.getOrDefault(key, -1)
    if keyIndex >= 0:
      t.data.delete(keyIndex)
      t.byKey = initTable[A, int]()
      populateByKey(t)

proc pop*[A, B](t: var OrderedTable[A, B], key: A, val: var B): bool =
  ## Deletes the ``key`` from the table.
  ## Returns ``true``, if the ``key`` existed, and sets ``val`` to the
  ## mapping of the key. Otherwise, returns ``false``, and the ``val`` is
  ## unchanged.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTable[A,B],A>`_
  ## * `delete proc<#delete,OrderedTable[A,B],A>`_
  ## * `clear proc<#clear,OrderedTable[A,B]>`_ to empty the whole table
  runnableExamples:
    var
      a = {'c': 5, 'b': 9, 'a': 13}.toOrderedTable
      i: int
    doAssert a.pop('b', i) == true
    doAssert a == {'c': 5, 'a': 13}.toOrderedTable
    doAssert i == 9
    i = 0
    doAssert a.pop('z', i) == false
    doAssert a == {'c': 5, 'a': 13}.toOrderedTable
    doAssert i == 0

  result = key in t
  if result:
    val = t[key]
    t.del(key)

proc clear*[A, B](t: var OrderedTable[A, B]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTable[A,B],A>`_
  ## * `delete proc<#delete,OrderedTable[A,B],A>`_
  ## * `pop proc<#pop,OrderedTable[A,B],A,B>`_
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toOrderedTable
    doAssert len(a) == 3
    clear(a)
    doAssert len(a) == 0

  t.data.setLen(0)
  t.byKey = initTable[A, int]()


template dollarImpl(): untyped {.dirty.} =
  if t.data.len == 0:
    result = "{:}"
  else:
    result = "{"
    for (k, v) in t.data:
      if result.len > 1: result.add(", ")
      result.addQuoted(k)
      result.add(": ")
      result.addQuoted(v)
    result.add("}")

proc `$`*[A, B](t: OrderedTable[A, B]): string =
  ## The ``$`` operator for ordered tables. Used internally when calling
  ## `echo` on a table.
  dollarImpl()

proc `==`*[A, B](s, t: OrderedTable[A, B]): bool =
  ## The ``==`` operator for ordered tables. Returns ``true`` if both the
  ## content and the order are equal.
  runnableExamples:
    let
      a = {'a': 5, 'b': 9, 'c': 13}.toOrderedTable
      b = {'b': 9, 'c': 13, 'a': 5}.toOrderedTable
    doAssert a != b

  if s.data.len != t.data.len:
    return false
  for i in 0 ..< s.data.len:
    if s.data[i] != t.data[i]:
      return false
  return true



iterator pairs*[A, B](t: OrderedTable[A, B]): (A, B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t`` in insertion
  ## order.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,OrderedTable[A,B]>`_
  ## * `keys iterator<#keys.i,OrderedTable[A,B]>`_
  ## * `values iterator<#values.i,OrderedTable[A,B]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = {
  ##     'o': [1, 5, 7, 9],
  ##     'e': [2, 4, 6, 8]
  ##     }.toOrderedTable
  ##
  ##   for k, v in a.pairs:
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: o
  ##   # value: [1, 5, 7, 9]
  ##   # key: e
  ##   # value: [2, 4, 6, 8]
  for p in t.data:
    yield p

iterator mpairs*[A, B](t: var OrderedTable[A, B]): (A, var B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t`` (must be
  ## declared as `var`) in insertion order. The values can be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTable[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,OrderedTable[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toOrderedTable
    for k, v in a.mpairs:
      v.add(v[0] + 10)
    doAssert a == {'o': @[1, 5, 7, 9, 11],
                   'e': @[2, 4, 6, 8, 12]}.toOrderedTable

  for i in 0 ..< t.data.len:
    yield (t.data[i][0], t.data[i][1])

iterator keys*[A, B](t: OrderedTable[A, B]): A =
  ## Iterates over any key in the table ``t`` in insertion order.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTable[A,B]>`_
  ## * `values iterator<#values.i,OrderedTable[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toOrderedTable
    for k in a.keys:
      a[k].add(99)
    doAssert a == {'o': @[1, 5, 7, 9, 99],
                   'e': @[2, 4, 6, 8, 99]}.toOrderedTable

  for (k, _) in t.data:
    yield k

iterator values*[A, B](t: OrderedTable[A, B]): B =
  ## Iterates over any value in the table ``t`` in insertion order.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTable[A,B]>`_
  ## * `keys iterator<#keys.i,OrderedTable[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,OrderedTable[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toOrderedTable
    for v in a.values:
      doAssert v.len == 4

  for (_, v) in t.data:
    yield v

iterator mvalues*[A, B](t: var OrderedTable[A, B]): var B =
  ## Iterates over any value in the table ``t`` (must be
  ## declared as `var`) in insertion order. The values
  ## can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,OrderedTable[A,B]>`_
  ## * `values iterator<#values.i,OrderedTable[A,B]>`_
  runnableExamples:
    var a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.toOrderedTable
    for v in a.mvalues:
      v.add(99)
    doAssert a == {'o': @[1, 5, 7, 9, 99],
                   'e': @[2, 4, 6, 8, 99]}.toOrderedTable

  for i in 0 ..< t.data.len:
    yield t.data[i][1]







# ---------------------------------------------------------------------------
# --------------------------- OrderedTableRef -------------------------------
# ---------------------------------------------------------------------------


proc newOrderedTable*[A, B](initialSize = 64): <//>OrderedTableRef[A, B] =
  ## Creates a new ordered ref table that is empty.
  ##
  ## See also:
  ## * `newOrderedTable proc<#newOrderedTable,openArray[]>`_ for creating
  ##   an `OrderedTableRef` from a collection of `(key, value)` pairs
  ## * `initOrderedTable proc<#initOrderedTable,int>`_ for creating an
  ##   `OrderedTable`
  runnableExamples:
    let
      a = newOrderedTable[int, string]()
      b = newOrderedTable[char, seq[int]]()
  new(result)
  result[] = initOrderedTable[A, B]()

proc newOrderedTable*[A, B](pairs: openArray[(A, B)]): <//>OrderedTableRef[A, B] =
  ## Creates a new ordered ref table that contains the given ``pairs``.
  ##
  ## ``pairs`` is a container consisting of ``(key, value)`` tuples.
  ##
  ## See also:
  ## * `newOrderedTable proc<#newOrderedTable,int>`_
  ## * `toOrderedTable proc<#toOrderedTable,openArray[]>`_ for an
  ##   `OrderedTable` version
  runnableExamples:
    let a = [('a', 5), ('b', 9)]
    let b = newOrderedTable(a)
    assert b == {'a': 5, 'b': 9}.newOrderedTable

  result = newOrderedTable[A, B]()
  for key, val in items(pairs): result[key] = val


proc `[]`*[A, B](t: OrderedTableRef[A, B], key: A): var B =
  ## Retrieves the value at ``t[key]``.
  ##
  ## If ``key`` is not in ``t``, the  ``KeyError`` exception is raised.
  ## One can check with `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_ whether
  ## the key exists.
  ##
  ## See also:
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `[]= proc<#[]=,OrderedTableRef[A,B],A,B>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_ for checking if
  ##   a key is in the table
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert a['a'] == 5
    doAssertRaises(KeyError):
      echo a['z']
  result = t[][key]

proc `[]=`*[A, B](t: OrderedTableRef[A, B], key: A, val: B) =
  ## Inserts a ``(key, value)`` pair into ``t``.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `del proc<#del,OrderedTableRef[A,B],A>`_ for removing a key from the table
  runnableExamples:
    var a = newOrderedTable[char, int]()
    a['x'] = 7
    a['y'] = 33
    doAssert a == {'x': 7, 'y': 33}.newOrderedTable

  t[][key] = val

proc hasKey*[A, B](t: OrderedTableRef[A, B], key: A): bool =
  ## Returns true if ``key`` is in the table ``t``.
  ##
  ## See also:
  ## * `contains proc<#contains,OrderedTableRef[A,B],A>`_ for use with the `in`
  ##   operator
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert a.hasKey('a') == true
    doAssert a.hasKey('z') == false

  result = t[].hasKey(key)

proc contains*[A, B](t: OrderedTableRef[A, B], key: A): bool =
  ## Alias of `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_ for use with
  ## the ``in`` operator.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert 'b' in a == true
    doAssert a.contains('z') == false

  return hasKey[A, B](t, key)

proc hasKeyOrPut*[A, B](t: var OrderedTableRef[A, B], key: A, val: B): bool =
  ## Returns true if ``key`` is in the table, otherwise inserts ``value``.
  ##
  ## See also:
  ## * `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.newOrderedTable
    if a.hasKeyOrPut('a', 50):
      a['a'] = 99
    if a.hasKeyOrPut('z', 50):
      a['z'] = 99
    doAssert a == {'a': 99, 'b': 9, 'z': 50}.newOrderedTable

  result = t[].hasKeyOrPut(key, val)

proc getOrDefault*[A, B](t: OrderedTableRef[A, B], key: A): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``. Otherwise, the
  ## default initialization value for type ``B`` is returned (e.g. 0 for any
  ## integer type).
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert a.getOrDefault('a') == 5
    doAssert a.getOrDefault('z') == 0

  getOrDefault(t[], key)

proc getOrDefault*[A, B](t: OrderedTableRef[A, B], key: A, default: B): B =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``.
  ## Otherwise, ``default`` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `mgetOrPut proc<#mgetOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert a.getOrDefault('a', 99) == 5
    doAssert a.getOrDefault('z', 99) == 99

  getOrDefault(t[], key, default)

proc mgetOrPut*[A, B](t: OrderedTableRef[A, B], key: A, val: B): var B =
  ## Retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  ##
  ## See also:
  ## * `[] proc<#[],OrderedTableRef[A,B],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,OrderedTableRef[A,B],A>`_
  ## * `hasKeyOrPut proc<#hasKeyOrPut,OrderedTableRef[A,B],A,B>`_
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A>`_ to return
  ##   a default value (e.g. zero for int) if the key doesn't exist
  ## * `getOrDefault proc<#getOrDefault,OrderedTableRef[A,B],A,B>`_ to return
  ##   a custom value if the key doesn't exist
  runnableExamples:
    var a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert a.mgetOrPut('a', 99) == 5
    doAssert a.mgetOrPut('z', 99) == 99
    doAssert a == {'a': 5, 'b': 9, 'z': 99}.newOrderedTable

  result = t[].mgetOrPut(key, val)


proc len*[A, B](t: OrderedTableRef[A, B]): int {.inline.} =
  ## Returns the number of keys in ``t``.
  runnableExamples:
    let a = {'a': 5, 'b': 9}.newOrderedTable
    doAssert len(a) == 2

  result = t.data.len


proc del*[A, B](t: OrderedTableRef[A, B], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## **NOTE**: This proc is destructive: the original order of the elements
  ## is not preserved!
  ##
  ## If you want to keep the order of elements after removal,
  ## use `delete proc<#delete,OrderedTableRef[A,B],A>`_.
  ##
  ## See also:
  ## * `delete proc<#delete,OrderedTableRef[A,B],A>`_
  ## * `pop proc<#pop,OrderedTableRef[A,B],A,B>`_
  ## * `clear proc<#clear,OrderedTableRef[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.newOrderedTable
    a.del('a')
    doAssert a == {'c': 13, 'b': 9}.newOrderedTable
    a.del('z')
    doAssert a == {'c': 13, 'b': 9}.newOrderedTable

  t[].del(key)

proc delete*[A, B](t: OrderedTableRef[A, B], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTableRef[A,B],A>`_ for faster version which doesn't
  ##   preserve the order
  ## * `pop proc<#pop,OrderedTableRef[A,B],A,B>`_
  ## * `clear proc<#clear,OrderedTableRef[A,B]>`_ to empty the whole table
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.toOrderedTable
    a.delete('a')
    doAssert a == {'b': 9, 'c': 13}.toOrderedTable
    a.delete('z')
    doAssert a == {'b': 9, 'c': 13}.toOrderedTable

  t[].delete(key)

proc pop*[A, B](t: OrderedTableRef[A, B], key: A, val: var B): bool =
  ## Deletes the ``key`` from the table.
  ## Returns ``true``, if the ``key`` existed, and sets ``val`` to the
  ## mapping of the key. Otherwise, returns ``false``, and the ``val`` is
  ## unchanged.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTableRef[A,B],A>`_
  ## * `clear proc<#clear,OrderedTableRef[A,B]>`_ to empty the whole table
  runnableExamples:
    var
      a = {'c': 5, 'b': 9, 'a': 13}.newOrderedTable
      i: int
    doAssert a.pop('b', i) == true
    doAssert a == {'c': 5, 'a': 13}.newOrderedTable
    doAssert i == 9
    i = 0
    doAssert a.pop('z', i) == false
    doAssert a == {'c': 5, 'a': 13}.newOrderedTable
    doAssert i == 0

  pop(t[], key, val)

proc clear*[A, B](t: OrderedTableRef[A, B]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,OrderedTableRef[A,B],A>`_
  runnableExamples:
    var a = {'a': 5, 'b': 9, 'c': 13}.newOrderedTable
    doAssert len(a) == 3
    clear(a)
    doAssert len(a) == 0

  clear(t[])

proc `$`*[A, B](t: OrderedTableRef[A, B]): string =
  ## The ``$`` operator for ordered tables. Used internally when calling
  ## `echo` on a table.
  dollarImpl()

proc `==`*[A, B](s, t: OrderedTableRef[A, B]): bool =
  ## The ``==`` operator for ordered tables. Returns true if either both
  ## tables are ``nil``, or neither is ``nil`` and the content and the order of
  ## both are equal.
  runnableExamples:
    let
      a = {'a': 5, 'b': 9, 'c': 13}.newOrderedTable
      b = {'b': 9, 'c': 13, 'a': 5}.newOrderedTable
    doAssert a != b

  if isNil(s): result = isNil(t)
  elif isNil(t): result = false
  else: result = s[] == t[]



iterator keys*[A, B](t: OrderedTableRef[A, B]): A =
  ## Iterates over any key in the table ``t`` in insertion order.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTableRef[A,B]>`_
  ## * `values iterator<#values.i,OrderedTableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newOrderedTable
    for k in a.keys:
      a[k].add(99)
    doAssert a == {'o': @[1, 5, 7, 9, 99], 'e': @[2, 4, 6, 8,
        99]}.newOrderedTable

  for k in keys(t[]):
    yield k

iterator values*[A, B](t: OrderedTableRef[A, B]): B =
  ## Iterates over any value in the table ``t`` in insertion order.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTableRef[A,B]>`_
  ## * `keys iterator<#keys.i,OrderedTableRef[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,OrderedTableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newOrderedTable
    for v in a.values:
      doAssert v.len == 4

  for v in values(t[]):
    yield v

iterator mvalues*[A, B](t: OrderedTableRef[A, B]): var B =
  ## Iterates over any value in the table ``t`` in insertion order. The values
  ## can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,OrderedTableRef[A,B]>`_
  ## * `values iterator<#values.i,OrderedTableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newOrderedTable
    for v in a.mvalues:
      v.add(99)
    doAssert a == {'o': @[1, 5, 7, 9, 99],
                   'e': @[2, 4, 6, 8, 99]}.newOrderedTable

  for v in mvalues(t[]):
    yield v

iterator pairs*[A, B](t: OrderedTableRef[A, B]): (A, B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t`` in insertion
  ## order.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,OrderedTableRef[A,B]>`_
  ## * `keys iterator<#keys.i,OrderedTableRef[A,B]>`_
  ## * `values iterator<#values.i,OrderedTableRef[A,B]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = {
  ##     'o': [1, 5, 7, 9],
  ##     'e': [2, 4, 6, 8]
  ##     }.newOrderedTable
  ##
  ##   for k, v in a.pairs:
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: o
  ##   # value: [1, 5, 7, 9]
  ##   # key: e
  ##   # value: [2, 4, 6, 8]

  for p in pairs(t[]):
    yield p

iterator mpairs*[A, B](t: OrderedTableRef[A, B]): (A, var B) =
  ## Iterates over any ``(key, value)`` pair in the table ``t`` in insertion
  ## order. The values can be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,OrderedTableRef[A,B]>`_
  ## * `mvalues iterator<#mvalues.i,OrderedTableRef[A,B]>`_
  runnableExamples:
    let a = {
      'o': @[1, 5, 7, 9],
      'e': @[2, 4, 6, 8]
      }.newOrderedTable
    for k, v in a.mpairs:
      v.add(v[0] + 10)
    doAssert a == {'o': @[1, 5, 7, 9, 11],
                   'e': @[2, 4, 6, 8, 12]}.newOrderedTable

  for (k, v) in mpairs(t[]):
    yield (k, v)





# -------------------------------------------------------------------------
# ------------------------------ CountTable -------------------------------
# -------------------------------------------------------------------------

type
  CountTable*[A] = object
    ## Table that counts the number of each key.
    ##
    ## For creating an empty CountTable, use `initCountTable proc
    ## <#initCountTable,int>`_.
    data: Table[A, int]

  CountTableRef*[A] = ref CountTable[A] ## Ref version of
    ## `CountTable<#CountTable>`_.
    ##
    ## For creating a new empty CountTableRef, use `newCountTable proc
    ## <#newCountTable,int>`_.

proc inc*[A](t: var CountTable[A], key: A, val: Positive = 1)


proc initCountTable*[A](initialSize = 64): CountTable[A] =
  ## Creates a new count table that is empty.
  ##
  ## Starting from Nim v0.20, tables are initialized by default and it is
  ## not necessary to call this function explicitly.
  ##
  ## See also:
  ## * `toCountTable proc<#toCountTable,openArray[A]>`_
  ## * `newCountTable proc<#newCountTable,int>`_ for creating a
  ##   `CountTableRef`
  result = CountTable[A](data: initTable[A, int]())

proc toCountTable*[A](keys: openArray[A]): CountTable[A] =
  ## Creates a new count table with every member of a container ``keys``
  ## having a count of how many times it occurs in that container.
  result = initCountTable[A](keys.len)
  for key in items(keys): result.inc(key)

proc `[]`*[A](t: CountTable[A], key: A): int =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``.
  ## Otherwise ``0`` is returned.
  ##
  ## See also:
  ## * `getOrDefault<#getOrDefault,CountTable[A],A,int>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `mget proc<#mget,CountTable[A],A>`_
  ## * `[]= proc<#[]%3D,CountTable[A],A,int>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,CountTable[A],A>`_ for checking if a key
  ##   is in the table
  getOrDefault(t.data, key)

proc `[]=`*[A](t: var CountTable[A], key: A, val: int) =
  ## Inserts a ``(key, value)`` pair into ``t``.
  ##
  ## See also:
  ## * `[] proc<#[],CountTable[A],A>`_ for retrieving a value of a key
  ## * `inc proc<#inc,CountTable[A],A,Positive>`_ for incrementing a
  ##   value of a key
  if val == 0:
    t.data.del(key)
  else:
    t.data[key] = val

proc inc*[A](t: var CountTable[A], key: A, val: Positive = 1) =
  ## Increments ``t[key]`` by ``val`` (default: 1).
  ##
  ## ``val`` must be a positive number. If you need to decrement a value,
  ## use a regular ``Table`` instead.
  runnableExamples:
    var a = toCountTable("aab")
    a.inc('a')
    a.inc('b', 10)
    doAssert a == toCountTable("aaabbbbbbbbbbb")

  var newValue = t[key] + val
  if newValue == 0:
    t.data.del(key)
  else:
    t.data[key] = newValue


proc smallest*[A](t: CountTable[A]): tuple[key: A, val: int] =
  ## Returns the ``(key, value)`` pair with the smallest ``val``. Efficiency: O(n)
  ##
  ## See also:
  ## * `largest proc<#largest,CountTable[A]>`_
  var first = true
  for (k, v) in pairs(t.data):
    if first or v < result.val:
      result.key = k
      result.val = v
      first = false

proc largest*[A](t: CountTable[A]): tuple[key: A, val: int] =
  ## Returns the ``(key, value)`` pair with the largest ``val``. Efficiency: O(n)
  ##
  ## See also:
  ## * `smallest proc<#smallest,CountTable[A]>`_
  var first = true
  for (k, v) in pairs(t.data):
    if first or v > result.val:
      result.key = k
      result.val = v
      first = false

proc hasKey*[A](t: CountTable[A], key: A): bool =
  ## Returns true if ``key`` is in the table ``t``.
  ##
  ## See also:
  ## * `contains proc<#contains,CountTable[A],A>`_ for use with the `in`
  ##   operator
  ## * `[] proc<#[],CountTable[A],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,CountTable[A],A,int>`_ to return
  ##   a custom value if the key doesn't exist
  hasKey(t.data, key)

proc contains*[A](t: CountTable[A], key: A): bool =
  ## Alias of `hasKey proc<#hasKey,CountTable[A],A>`_ for use with
  ## the ``in`` operator.
  return hasKey[A](t, key)

proc getOrDefault*[A](t: CountTable[A], key: A; default: int = 0): int =
  ## Retrieves the value at ``t[key]`` if``key`` is in ``t``. Otherwise, the
  ## integer value of ``default`` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],CountTable[A],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,CountTable[A],A>`_ for checking if a key
  ##   is in the table
  getOrDefault(t.data, key, default)

proc len*[A](t: CountTable[A]): int =
  ## Returns the number of keys in ``t``.
  t.data.len

proc del*[A](t: var CountTable[A], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `pop proc<#pop,CountTable[A],A,int>`_
  ## * `clear proc<#clear,CountTable[A]>`_ to empty the whole table
  runnableExamples:
    var a = toCountTable("aabbbccccc")
    a.del('b')
    assert a == toCountTable("aaccccc")
    a.del('b')
    assert a == toCountTable("aaccccc")
    a.del('c')
    assert a == toCountTable("aa")

  del(t.data, key)

proc pop*[A](t: var CountTable[A], key: A, val: var int): bool =
  ## Deletes the ``key`` from the table.
  ## Returns ``true``, if the ``key`` existed, and sets ``val`` to the
  ## mapping of the key. Otherwise, returns ``false``, and the ``val`` is
  ## unchanged.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `del proc<#del,CountTable[A],A>`_
  ## * `clear proc<#clear,CountTable[A]>`_ to empty the whole table
  runnableExamples:
    var a = toCountTable("aabbbccccc")
    var i = 0
    assert a.pop('b', i)
    assert i == 3
    i = 99
    assert not a.pop('b', i)
    assert i == 99

  pop(t.data, key, val)

proc clear*[A](t: var CountTable[A]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,CountTable[A],A>`_
  ## * `pop proc<#pop,CountTable[A],A,int>`_

  # XXX: can we simplify it like this?
  t.data = initTable[A, int]()

proc merge*[A](s: var CountTable[A], t: CountTable[A]) =
  ## Merges the second table into the first one (must be declared as `var`).
  runnableExamples:
    var a = toCountTable("aaabbc")
    let b = toCountTable("bcc")
    a.merge(b)
    doAssert a == toCountTable("aaabbbccc")

  for (k, v) in pairs(t.data):
    s.inc(k, v)

proc `$`*[A](t: CountTable[A]): string =
  ## The ``$`` operator for count tables. Used internally when calling `echo`
  ## on a table.
  `$`(t.data)

proc `==`*[A](s, t: CountTable[A]): bool =
  ## The ``==`` operator for count tables. Returns ``true`` if both tables
  ## contain the same keys with the same count. Insert order does not matter.
  if s.data.len != t.data.len:
    return false
  for (k, v) in pairs(s.data):
    if t.data[k] != v:
      return false
  return true

iterator pairs*[A](t: CountTable[A]): (A, int) =
  ## Iterates over any ``(key, value)`` pair in the table ``t``.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,CountTable[A]>`_
  ## * `keys iterator<#keys.i,CountTable[A]>`_
  ## * `values iterator<#values.i,CountTable[A]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = toCountTable("abracadabra")
  ##
  ##   for k, v in pairs(a):
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: a
  ##   # value: 5
  ##   # key: b
  ##   # value: 2
  ##   # key: c
  ##   # value: 1
  ##   # key: d
  ##   # value: 1
  ##   # key: r
  ##   # value: 2
  for p in pairs(t.data):
    yield p

iterator mpairs*[A](t: var CountTable[A]): (A, var int) =
  ## Iterates over any ``(key, value)`` pair in the table ``t`` (must be
  ## declared as `var`). The values can be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTable[A]>`_
  ## * `mvalues iterator<#mvalues.i,CountTable[A]>`_
  runnableExamples:
    var a = toCountTable("abracadabra")
    for k, v in mpairs(a):
      v = 2
    doAssert a == toCountTable("aabbccddrr")

  for (k, v) in mpairs(t.data):
    yield (k, v)

iterator keys*[A](t: CountTable[A]): A =
  ## Iterates over any key in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTable[A]>`_
  ## * `values iterator<#values.i,CountTable[A]>`_
  runnableExamples:
    var a = toCountTable("abracadabra")
    for k in keys(a):
      a[k] = 2
    doAssert a == toCountTable("aabbccddrr")

  for k in keys(t.data):
    yield k

iterator values*[A](t: CountTable[A]): int =
  ## Iterates over any value in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTable[A]>`_
  ## * `keys iterator<#keys.i,CountTable[A]>`_
  ## * `mvalues iterator<#mvalues.i,CountTable[A]>`_
  runnableExamples:
    let a = toCountTable("abracadabra")
    for v in values(a):
      assert v < 10

  for v in values(t.data):
    yield v

iterator mvalues*[A](t: var CountTable[A]): var int =
  ## Iterates over any value in the table ``t`` (must be
  ## declared as `var`). The values can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,CountTable[A]>`_
  ## * `values iterator<#values.i,CountTable[A]>`_
  runnableExamples:
    var a = toCountTable("abracadabra")
    for v in mvalues(a):
      v = 2
    doAssert a == toCountTable("aabbccddrr")

  for v in mvalues(t.data):
    yield v





# ---------------------------------------------------------------------------
# ---------------------------- CountTableRef --------------------------------
# ---------------------------------------------------------------------------


proc inc*[A](t: CountTableRef[A], key: A, val = 1)

proc newCountTable*[A](initialSize = 64): <//>CountTableRef[A] =
  ## Creates a new ref count table that is empty.
  ##
  ## See also:
  ## * `newCountTable proc<#newCountTable,openArray[A]>`_ for creating
  ##   a `CountTableRef` from a collection
  ## * `initCountTable proc<#initCountTable,int>`_ for creating a
  ##   `CountTable`
  new(result)
  result[] = initCountTable[A]()

proc newCountTable*[A](keys: openArray[A]): <//>CountTableRef[A] =
  ## Creates a new ref count table with every member of a container ``keys``
  ## having a count of how many times it occurs in that container.
  result = newCountTable[A]()
  for key in items(keys): result.inc(key)

proc `[]`*[A](t: CountTableRef[A], key: A): int =
  ## Retrieves the value at ``t[key]`` if ``key`` is in ``t``.
  ## Otherwise ``0`` is returned.
  ##
  ## See also:
  ## * `getOrDefault<#getOrDefault,CountTableRef[A],A,int>`_ to return
  ##   a custom value if the key doesn't exist
  ## * `mget proc<#mget,CountTableRef[A],A>`_
  ## * `[]= proc<#[]%3D,CountTableRef[A],A,int>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc<#hasKey,CountTableRef[A],A>`_ for checking if a key
  ##   is in the table
  result = t[][key]


proc `[]=`*[A](t: CountTableRef[A], key: A, val: int) =
  ## Inserts a ``(key, value)`` pair into ``t``.
  ##
  ## See also:
  ## * `[] proc<#[],CountTableRef[A],A>`_ for retrieving a value of a key
  ## * `inc proc<#inc,CountTableRef[A],A,int>`_ for incrementing a
  ##   value of a key
  assert val > 0
  t[][key] = val

proc inc*[A](t: CountTableRef[A], key: A, val = 1) =
  ## Increments ``t[key]`` by ``val`` (default: 1).
  runnableExamples:
    var a = newCountTable("aab")
    a.inc('a')
    a.inc('b', 10)
    doAssert a == newCountTable("aaabbbbbbbbbbb")
  t[].inc(key, val)

proc smallest*[A](t: CountTableRef[A]): (A, int) =
  ## Returns the ``(key, value)`` pair with the smallest ``val``. Efficiency: O(n)
  ##
  ## See also:
  ## * `largest proc<#largest,CountTableRef[A]>`_
  t[].smallest

proc largest*[A](t: CountTableRef[A]): (A, int) =
  ## Returns the ``(key, value)`` pair with the largest ``val``. Efficiency: O(n)
  ##
  ## See also:
  ## * `smallest proc<#smallest,CountTable[A]>`_
  t[].largest

proc hasKey*[A](t: CountTableRef[A], key: A): bool =
  ## Returns true if ``key`` is in the table ``t``.
  ##
  ## See also:
  ## * `contains proc<#contains,CountTableRef[A],A>`_ for use with the `in`
  ##   operator
  ## * `[] proc<#[],CountTableRef[A],A>`_ for retrieving a value of a key
  ## * `getOrDefault proc<#getOrDefault,CountTableRef[A],A,int>`_ to return
  ##   a custom value if the key doesn't exist
  result = t[].hasKey(key)

proc contains*[A](t: CountTableRef[A], key: A): bool =
  ## Alias of `hasKey proc<#hasKey,CountTableRef[A],A>`_ for use with
  ## the ``in`` operator.
  return hasKey[A](t, key)

proc getOrDefault*[A](t: CountTableRef[A], key: A, default: int): int =
  ## Retrieves the value at ``t[key]`` if``key`` is in ``t``. Otherwise, the
  ## integer value of ``default`` is returned.
  ##
  ## See also:
  ## * `[] proc<#[],CountTableRef[A],A>`_ for retrieving a value of a key
  ## * `hasKey proc<#hasKey,CountTableRef[A],A>`_ for checking if a key
  ##   is in the table
  result = t[].getOrDefault(key, default)

proc len*[A](t: CountTableRef[A]): int =
  ## Returns the number of keys in ``t``.
  result = t.data.len

proc del*[A](t: CountTableRef[A], key: A) =
  ## Deletes ``key`` from table ``t``. Does nothing if the key does not exist.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `pop proc<#pop,CountTableRef[A],A,int>`_
  ## * `clear proc<#clear,CountTableRef[A]>`_ to empty the whole table
  del(t[], key)

proc pop*[A](t: CountTableRef[A], key: A, val: var int): bool =
  ## Deletes the ``key`` from the table.
  ## Returns ``true``, if the ``key`` existed, and sets ``val`` to the
  ## mapping of the key. Otherwise, returns ``false``, and the ``val`` is
  ## unchanged.
  ##
  ## O(n) complexity.
  ##
  ## See also:
  ## * `del proc<#del,CountTableRef[A],A>`_
  ## * `clear proc<#clear,CountTableRef[A]>`_ to empty the whole table
  pop(t[], key, val)

proc clear*[A](t: CountTableRef[A]) =
  ## Resets the table so that it is empty.
  ##
  ## See also:
  ## * `del proc<#del,CountTableRef[A],A>`_
  ## * `pop proc<#pop,CountTableRef[A],A,int>`_
  clear(t[])

proc merge*[A](s, t: CountTableRef[A]) =
  ## Merges the second table into the first one.
  runnableExamples:
    let
      a = newCountTable("aaabbc")
      b = newCountTable("bcc")
    a.merge(b)
    doAssert a == newCountTable("aaabbbccc")

  s[].merge(t[])


proc `$`*[A](t: CountTableRef[A]): string =
  ## The ``$`` operator for count tables. Used internally when calling `echo`
  ## on a table.
  `$`(t.data)

proc `==`*[A](s, t: CountTableRef[A]): bool =
  ## The ``==`` operator for count tables. Returns ``true`` if either both tables
  ## are ``nil``, or neither is ``nil`` and both contain the same keys with the same
  ## count. Insert order does not matter.
  if isNil(s): result = isNil(t)
  elif isNil(t): result = false
  else: result = s[] == t[]




iterator keys*[A](t: CountTableRef[A]): A =
  ## Iterates over any key in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTable[A]>`_
  ## * `values iterator<#values.i,CountTable[A]>`_
  runnableExamples:
    let a = newCountTable("abracadabra")
    for k in keys(a):
      a[k] = 2
    doAssert a == newCountTable("aabbccddrr")

  for k in keys(t[]):
    yield k

iterator values*[A](t: CountTableRef[A]): int =
  ## Iterates over any value in the table ``t``.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTableRef[A]>`_
  ## * `keys iterator<#keys.i,CountTableRef[A]>`_
  ## * `mvalues iterator<#mvalues.i,CountTableRef[A]>`_
  runnableExamples:
    let a = newCountTable("abracadabra")
    for v in values(a):
      assert v < 10

  for v in values(t[]):
    yield v

iterator mvalues*[A](t: CountTableRef[A]): var int =
  ## Iterates over any value in the table ``t``. The values can be modified.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,CountTableRef[A]>`_
  ## * `values iterator<#values.i,CountTableRef[A]>`_
  runnableExamples:
    var a = newCountTable("abracadabra")
    for v in mvalues(a):
      v = 2
    doAssert a == newCountTable("aabbccddrr")

  for v in mvalues(t[]):
    yield v

iterator pairs*[A](t: CountTableRef[A]): (A, int) =
  ## Iterates over any ``(key, value)`` pair in the table ``t``.
  ##
  ## See also:
  ## * `mpairs iterator<#mpairs.i,CountTableRef[A]>`_
  ## * `keys iterator<#keys.i,CountTableRef[A]>`_
  ## * `values iterator<#values.i,CountTableRef[A]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let a = newCountTable("abracadabra")
  ##
  ##   for k, v in pairs(a):
  ##     echo "key: ", k
  ##     echo "value: ", v
  ##
  ##   # key: a
  ##   # value: 5
  ##   # key: b
  ##   # value: 2
  ##   # key: c
  ##   # value: 1
  ##   # key: d
  ##   # value: 1
  ##   # key: r
  ##   # value: 2
  for p in pairs(t[]):
    yield p

iterator mpairs*[A](t: CountTableRef[A]): (A, var int) =
  ## Iterates over any ``(key, value)`` pair in the table ``t``. The values can
  ## be modified.
  ##
  ## See also:
  ## * `pairs iterator<#pairs.i,CountTableRef[A]>`_
  ## * `mvalues iterator<#mvalues.i,CountTableRef[A]>`_
  runnableExamples:
    let a = newCountTable("abracadabra")
    for k, v in mpairs(a):
      v = 2
    doAssert a == newCountTable("aabbccddrr")

  for (k, v) in mpairs(t[]):
    yield (k, v)
