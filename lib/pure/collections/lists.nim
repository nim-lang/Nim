#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of:
## * `singly linked lists <#SinglyLinkedList>`_
## * `doubly linked lists <#DoublyLinkedList>`_
## * `singly linked rings <#SinglyLinkedRing>`_ (circular lists)
## * `doubly linked rings <#DoublyLinkedRing>`_ (circular lists)
##
##
## Basic Usage
## ===========
##
## Because it makes no sense to do otherwise, the `next` and `prev` pointers
## are not hidden from you and can be manipulated directly for efficiency.
##
## Lists
## -----
##
## .. code-block::
##   import lists
##
##   var
##     l = initDoublyLinkedList[int]()
##     a = newDoublyLinkedNode[int](3)
##     b = newDoublyLinkedNode[int](7)
##     c = newDoublyLinkedNode[int](9)
##
##   l.append(a)
##   l.append(b)
##   l.prepend(c)
##
##   assert a.next == b
##   assert a.prev == c
##   assert c.next == a
##   assert c.next.next == b
##   assert c.prev == nil
##   assert b.next == nil
##
##
## Rings
## -----
##
## .. code-block::
##   import lists
##
##   var
##     l = initSinglyLinkedRing[int]()
##     a = newSinglyLinkedNode[int](3)
##     b = newSinglyLinkedNode[int](7)
##     c = newSinglyLinkedNode[int](9)
##
##   l.append(a)
##   l.append(b)
##   l.prepend(c)
##
##   assert c.next == a
##   assert a.next == b
##   assert c.next.next == b
##   assert b.next == c
##   assert c.next.next.next == c
##
## See also
## ========
##
## * `deques module <deques.html>`_ for double-ended queues
## * `sharedlist module <sharedlist.html>`_ for shared singly-linked lists


when not defined(nimhygiene):
  {.pragma: dirty.}

when not defined(nimHasCursor):
  {.pragma: cursor.}

type
  DoublyLinkedNodeObj*[T] = object ## \
    ## A node a doubly linked list consists of.
    ##
    ## It consists of a `value` field, and pointers to `next` and `prev`.
    next*: <//>(ref DoublyLinkedNodeObj[T])
    prev* {.cursor.}: ref DoublyLinkedNodeObj[T]
    value*: T
  DoublyLinkedNode*[T] = ref DoublyLinkedNodeObj[T]

  SinglyLinkedNodeObj*[T] = object ## \
    ## A node a singly linked list consists of.
    ##
    ## It consists of a `value` field, and a pointer to `next`.
    next*: <//>(ref SinglyLinkedNodeObj[T])
    value*: T
  SinglyLinkedNode*[T] = ref SinglyLinkedNodeObj[T]

  SinglyLinkedList*[T] = object ## \
    ## A singly linked list.
    ##
    ## Use `initSinglyLinkedList proc <#initSinglyLinkedList>`_ to create
    ## a new empty list.
    head*: <//>(SinglyLinkedNode[T])
    tail* {.cursor.}: SinglyLinkedNode[T]

  DoublyLinkedList*[T] = object ## \
    ## A doubly linked list.
    ##
    ## Use `initDoublyLinkedList proc <#initDoublyLinkedList>`_ to create
    ## a new empty list.
    head*: <//>(DoublyLinkedNode[T])
    tail* {.cursor.}: DoublyLinkedNode[T]

  SinglyLinkedRing*[T] = object ## \
    ## A singly linked ring.
    ##
    ## Use `initSinglyLinkedRing proc <#initSinglyLinkedRing>`_ to create
    ## a new empty ring.
    head*: <//>(SinglyLinkedNode[T])
    tail* {.cursor.}: SinglyLinkedNode[T]

  DoublyLinkedRing*[T] = object ## \
    ## A doubly linked ring.
    ##
    ## Use `initDoublyLinkedRing proc <#initDoublyLinkedRing>`_ to create
    ## a new empty ring.
    head*: DoublyLinkedNode[T]

  SomeLinkedList*[T] = SinglyLinkedList[T] | DoublyLinkedList[T]

  SomeLinkedRing*[T] = SinglyLinkedRing[T] | DoublyLinkedRing[T]

  SomeLinkedCollection*[T] = SomeLinkedList[T] | SomeLinkedRing[T]

  SomeLinkedNode*[T] = SinglyLinkedNode[T] | DoublyLinkedNode[T]

proc initSinglyLinkedList*[T](): SinglyLinkedList[T] =
  ## Creates a new singly linked list that is empty.
  runnableExamples:
    var a = initSinglyLinkedList[int]()
  discard

proc initDoublyLinkedList*[T](): DoublyLinkedList[T] =
  ## Creates a new doubly linked list that is empty.
  runnableExamples:
    var a = initDoublyLinkedList[int]()
  discard

proc initSinglyLinkedRing*[T](): SinglyLinkedRing[T] =
  ## Creates a new singly linked ring that is empty.
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
  discard

proc initDoublyLinkedRing*[T](): DoublyLinkedRing[T] =
  ## Creates a new doubly linked ring that is empty.
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
  discard

proc newDoublyLinkedNode*[T](value: T): <//>(DoublyLinkedNode[T]) =
  ## Creates a new doubly linked node with the given `value`.
  runnableExamples:
    var n = newDoublyLinkedNode[int](5)
    assert n.value == 5

  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): <//>(SinglyLinkedNode[T]) =
  ## Creates a new singly linked node with the given `value`.
  runnableExamples:
    var n = newSinglyLinkedNode[int](5)
    assert n.value == 5

  new(result)
  result.value = value

template itemsListImpl() {.dirty.} =
  var it = L.head
  while it != nil:
    yield it.value
    it = it.next

template itemsRingImpl() {.dirty.} =
  var it = L.head
  if it != nil:
    while true:
      yield it.value
      it = it.next
      if it == L.head: break

iterator items*[T](L: SomeLinkedList[T]): T =
  ## Yields every value of `L`.
  ##
  ## See also:
  ## * `mitems iterator <#mitems.i,SomeLinkedList[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedList[T]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   var a = initSinglyLinkedList[int]()
  ##   for i in 1 .. 3:
  ##     a.append(10*i)
  ##
  ##   for x in a:  # the same as: for x in items(a):
  ##     echo x
  ##
  ##   # 10
  ##   # 20
  ##   # 30
  itemsListImpl()

iterator items*[T](L: SomeLinkedRing[T]): T =
  ## Yields every value of `L`.
  ##
  ## See also:
  ## * `mitems iterator <#mitems.i,SomeLinkedRing[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedRing[T]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   var a = initSinglyLinkedRing[int]()
  ##   for i in 1 .. 3:
  ##     a.append(10*i)
  ##
  ##   for x in a:  # the same as: for x in items(a):
  ##     echo x
  ##
  ##   # 10
  ##   # 20
  ##   # 30
  itemsRingImpl()

iterator mitems*[T](L: var SomeLinkedList[T]): var T =
  ## Yields every value of `L` so that you can modify it.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedList[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedList[T]>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    for i in 1 .. 5:
      a.append(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5*x - 1
    assert $a == "[49, 99, 149, 199, 249]"
  itemsListImpl()

iterator mitems*[T](L: var SomeLinkedRing[T]): var T =
  ## Yields every value of `L` so that you can modify it.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedRing[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedRing[T]>`_
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    for i in 1 .. 5:
      a.append(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5*x - 1
    assert $a == "[49, 99, 149, 199, 249]"
  itemsRingImpl()

iterator nodes*[T](L: SomeLinkedList[T]): SomeLinkedNode[T] =
  ## Iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedList[T]>`_
  ## * `mitems iterator <#mitems.i,SomeLinkedList[T]>`_
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    for i in 1 .. 5:
      a.append(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in nodes(a):
      if x.value == 30:
        a.remove(x)
      else:
        x.value = 5*x.value - 1
    assert $a == "[49, 99, 199, 249]"

  var it = L.head
  while it != nil:
    var nxt = it.next
    yield it
    it = nxt

iterator nodes*[T](L: SomeLinkedRing[T]): SomeLinkedNode[T] =
  ## Iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedRing[T]>`_
  ## * `mitems iterator <#mitems.i,SomeLinkedRing[T]>`_
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    for i in 1 .. 5:
      a.append(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in nodes(a):
      if x.value == 30:
        a.remove(x)
      else:
        x.value = 5*x.value - 1
    assert $a == "[49, 99, 199, 249]"

  var it = L.head
  if it != nil:
    while true:
      var nxt = it.next
      yield it
      it = nxt
      if it == L.head: break

proc `$`*[T](L: SomeLinkedCollection[T]): string =
  ## Turns a list into its string representation for logging and printing.
  result = "["
  for x in nodes(L):
    if result.len > 1: result.add(", ")
    result.addQuoted(x.value)
  result.add("]")

proc find*[T](L: SomeLinkedCollection[T], value: T): SomeLinkedNode[T] =
  ## Searches in the list for a value. Returns `nil` if the value does not
  ## exist.
  ##
  ## See also:
  ## * `contains proc <#contains,SomeLinkedCollection[T],T>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.append(9)
    a.append(8)
    assert a.find(9).value == 9
    assert a.find(1) == nil

  for x in nodes(L):
    if x.value == value: return x

proc contains*[T](L: SomeLinkedCollection[T], value: T): bool {.inline.} =
  ## Searches in the list for a value. Returns `false` if the value does not
  ## exist, `true` otherwise.
  ##
  ## See also:
  ## * `find proc <#find,SomeLinkedCollection[T],T>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.append(9)
    a.append(8)
    assert a.contains(9)
    assert 8 in a
    assert(not a.contains(1))
    assert 2 notin a

  result = find(L, value) != nil

proc append*[T](L: var SinglyLinkedList[T],
                n: SinglyLinkedNode[T]) {.inline.} =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedList[int]()
      n = newSinglyLinkedNode[int](9)
    a.append(n)
    assert a.contains(9)

  n.next = nil
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.append(9)
    a.append(8)
    assert a.contains(9)
  append(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedList[T],
                 n: SinglyLinkedNode[T]) {.inline.} =
  ## Prepends (adds to the beginning) a node to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedList[int]()
      n = newSinglyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  n.next = L.head
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Prepends (adds to the beginning) a node to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newSinglyLinkedNode(value))



proc append*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedList[int]()
      n = newDoublyLinkedNode[int](9)
    a.append(n)
    assert a.contains(9)

  n.next = nil
  n.prev = L.tail
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var DoublyLinkedList[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    a.append(9)
    a.append(8)
    assert a.contains(9)
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedList[int]()
      n = newDoublyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  n.prev = nil
  n.next = L.head
  if L.head != nil:
    assert(L.head.prev == nil)
    L.head.prev = n
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var DoublyLinkedList[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Removes a node `n` from `L`. Efficiency: O(1).
  runnableExamples:
    var
      a = initDoublyLinkedList[int]()
      n = newDoublyLinkedNode[int](5)
    a.append(n)
    assert 5 in a
    a.remove(n)
    assert 5 notin a

  if n == L.tail: L.tail = n.prev
  if n == L.head: L.head = n.next
  if n.next != nil: n.next.prev = n.prev
  if n.prev != nil: n.prev.next = n.next



proc append*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedRing[int]()
      n = newSinglyLinkedNode[int](9)
    a.append(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
    L.tail = n
  else:
    n.next = n
    L.head = n
    L.tail = n

proc append*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    a.append(9)
    a.append(8)
    assert a.contains(9)
  append(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedRing[int]()
      n = newSinglyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
  else:
    n.next = n
    L.tail = n
  L.head = n

proc prepend*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newSinglyLinkedNode(value))



proc append*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](9)
    a.append(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    n.prev = L.head.prev
    L.head.prev.next = n
    L.head.prev = n
  else:
    n.prev = n
    n.next = n
    L.head = n

proc append*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    a.append(9)
    a.append(8)
    assert a.contains(9)
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    n.prev = L.head.prev
    L.head.prev.next = n
    L.head.prev = n
  else:
    n.prev = n
    n.next = n
  L.head = n

proc prepend*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `append proc <#append,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `append proc <#append,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Removes `n` from `L`. Efficiency: O(1).
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](5)
    a.append(n)
    assert 5 in a
    a.remove(n)
    assert 5 notin a

  n.next.prev = n.prev
  n.prev.next = n.next
  if n == L.head:
    var p = L.head.prev
    if p == L.head:
      # only one element left:
      L.head = nil
    else:
      L.head = L.head.prev
