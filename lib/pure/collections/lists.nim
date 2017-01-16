#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of singly and doubly linked lists and rings.
##
## Because it makes no sense to do so, the ``next`` and ``prev``
## pointers are not hidden from you and can
## be manipulated directly for efficiency.
##
## * ``DoublyLinkedList`` and ``DoublyLinkedRing`` are ``O(1)`` to `remove` elements
## * ``SinglyLinkedList`` and ``SingleLinkedRing`` are ``O(n)`` to `remove` elements `(with lower memory usage)`
##
## Initializing a list/ring
## ====================
##
## .. code-block:: Nim
##   import lists, random
##   var
##     emptyIntDlr = initDoublyLinkedRing[int]()
##     emptyStrSll = initSinglyLinkedList[string]()
##     sll = @[1, 2, 3, 4].toSinglyLinkedList()
##     dll = @[1, 2, 3, 4].toDoublyLinkedList()
##     slr = @[1, 2, 3, 4].toSinglyLinkedRing()
##     dlr = @[1, 2, 3, 4].toDoublyLinkedRing()
##     randDll = newDoublyLinkedListWith(10, random(100))  # dll of 10 random numbers
##   echo randDll
##
## Converting a list/ring
## ======================
##
## .. code-block:: nim
##   import lists
##   var
##     sll = @[1, 2, 3, 4].toSinglyLinkedList()
##     sqSll = sll.toSeq
##     dll = @[1, 2, 3, 4].toDoublyLinkedList()
##     sqDll = dll.toSeq
##     slr = @[1, 2, 3, 4].toSinglyLinkedRing()
##     sqSlr = slr.toSeq
##     dlr = @[1, 2, 3, 4].toDoublyLinkedRing()
##     sqDlr = dlr.toSeq
##
## Transforming a list/ring
## ========================
##
## .. code-block:: nim
##   import lists
##   var
##     sll1 = @[1, 2, 3, 4].toSinglyLinkedList()
##     sll2 = map(sll1, proc(x: int): string = $x)  # MAP
##     dll1 = @[1, 2, 3, 4].toDoublyLinkedList()
##     dll2 = map(dll1, proc(x: int): string = $x)  # MAP
##     slr1 = @[1, 2, 3, 4].toSinglyLinkedRing()
##     slr2 = map(slr1, proc(x: int): string = $x)  # MAP
##     dlr1 = @[1, 2, 3, 4].toDoublyLinkedRing()
##     dlr2 = map(dlr1, proc(x: int): string = $x)  # MAP
##
##   assert sll2 == @["1", "2", "3", "4"].toSinglyLinkedList()
##   assert dll2 == @["1", "2", "3", "4"].toDoublyLinkedList()
##   assert slr2 == @["1", "2", "3", "4"].toSinglyLinkedRing()
##   assert dlr2 == @["1", "2", "3", "4"].toDoublyLinkedRing()
##
##   var sll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(sll, proc(x: var string) = x &= "42")  # APPLY #1
##   echo sll   # --> ["142", "242", "342", "442"]
##
##   var dll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dll, proc(x: var string) = x &= "42")  # APPLY #1
##   echo dll   # --> ["142", "242", "342", "442"]
##
##   var slr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(slr, proc(x: var string) = x &= "42")  # APPLY #1
##   echo slr   # --> ["142", "242", "342", "442"]
##
##   var dlr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dlr, proc(x: var string) = x &= "42")  # APPLY #1
##   echo dlr   # --> ["142", "242", "342", "442"]
##
##   sll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(sll, proc(x: var string) = x &= "42")  # APPLY #2
##   echo sll   # --> ["142", "242", "342", "442"]
##
##   dll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dll, proc(x: var string) = x &= "42")  # APPLY #2
##   echo dll   # --> ["142", "242", "342", "442"]
##
##   slr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(slr, proc(x: var string) = x &= "42")  # APPLY #2
##   echo slr   # --> ["142", "242", "342", "442"]
##
##   dlr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dlr, proc(x: var string) = x &= "42")  # APPLY #2
##   echo dlr   # --> ["142", "242", "342", "442"]
##
## **Using future module**
##
## .. code-block:: nim
##   import lists, future
##   var
##     sll1 = @[1, 2, 3, 4].toSinglyLinkedList()
##     sll2 = map(sll1, (x) => $x)  # MAP
##     dll1 = @[1, 2, 3, 4].toDoublyLinkedList()
##     dll2 = map(dll1, (x) => $x)  # MAP
##     slr1 = @[1, 2, 3, 4].toSinglyLinkedRing()
##     slr2 = map(slr1, (x) => $x)  # MAP
##     dlr1 = @[1, 2, 3, 4].toDoublyLinkedRing()
##     dlr2 = map(dlr1, (x) => $x)  # MAP
##
##   assert sll2 == @["1", "2", "3", "4"].toSinglyLinkedList()
##   assert dll2 == @["1", "2", "3", "4"].toDoublyLinkedList()
##   assert slr2 == @["1", "2", "3", "4"].toSinglyLinkedRing()
##   assert dlr2 == @["1", "2", "3", "4"].toDoublyLinkedRing()
##
##   var sll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(sll, (x) => $x & "42")  # APPLY #2
##   echo sll   # --> ["142", "242", "342", "442"]
##
##   var dll = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dll, (x) => $x & "42")  # APPLY #2
##   echo dll   # --> ["142", "242", "342", "442"]
##
##   var slr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(slr, (x) => $x & "42")  # APPLY #2
##   echo slr   # --> ["142", "242", "342", "442"]
##
##   var dlr = @["1", "2", "3", "4"].toSinglyLinkedList()
##   apply(dlr, (x) => $x & "42")  # APPLY #2
##   echo dlr   # --> ["142", "242", "342", "442"]

when not defined(nimhygiene):
  {.pragma: dirty.}

type
  SinglyLinkedNodeObj*[T] = object ## a ``node`` of a singly linked list
                                   ## consists of
    next*: ref SinglyLinkedNodeObj[T]
    value*: T
  SinglyLinkedNode*[T] = ref SinglyLinkedNodeObj[T]

  DoublyLinkedNodeObj*[T] = object ## a ``node`` of a doubly linked list
                                   ## consists of
    next*, prev*: ref DoublyLinkedNodeObj[T]
    value*: T
  DoublyLinkedNode*[T] = ref DoublyLinkedNodeObj[T]

  SinglyLinkedList*[T] = object ## a singly linked list
    head*, tail*: SinglyLinkedNode[T]

  DoublyLinkedList*[T] = object ## a doubly linked list
    head*, tail*: DoublyLinkedNode[T]

  SinglyLinkedRing*[T] = object ## a singly linked ring
    head*, tail*: SinglyLinkedNode[T]

  DoublyLinkedRing*[T] = object ## a doubly linked ring
    head*: DoublyLinkedNode[T]

{.deprecated: [TDoublyLinkedNode: DoublyLinkedNodeObj,
    PDoublyLinkedNode: DoublyLinkedNode,
    TSinglyLinkedNode: SinglyLinkedNodeObj,
    PSinglyLinkedNode: SinglyLinkedNode,
    TDoublyLinkedList: DoublyLinkedList,
    TSinglyLinkedRing: SinglyLinkedRing,
    TDoublyLinkedRing: DoublyLinkedRing,
    TSinglyLinkedList: SinglyLinkedList].}

proc initSinglyLinkedList*[T](): SinglyLinkedList[T] =
  ## Creates a new singly linked list that is empty.
  ##
  ## For initialisation with multiple values, use
  ## `toSinglyLinkedList() <#toSinglyLinkedList>`_
  ## or `newSinglyLinkedListWith() <#newSinglyLinkedListWith>`_
  discard

proc initDoublyLinkedList*[T](): DoublyLinkedList[T] =
  ## creates a new doubly linked list that is empty.
  ##
  ## For initialisation with multiple values, use
  ## `toDoublyLinkedList() <#toDoublyLinkedList>`_
  ## or `newDoublyLinkedListWith() <#newDoublyLinkedListWith>`_
  discard

proc initSinglyLinkedRing*[T](): SinglyLinkedRing[T] =
  ## creates a new singly linked ring that is empty.
  ##
  ## For initialisation with multiple values, use
  ## `toSinglyLinkedRing() <#toSinglyLinkedRing>`_
  ## or `newSinglyLinkedRingWith() <#newSinglyLinkedRingWith>`_
  discard

proc initDoublyLinkedRing*[T](): DoublyLinkedRing[T] =
  ## creates a new doubly linked ring that is empty.
  ##
  ## For initialisation with multiple values, use
  ## `toDoublyLinkedRing() <#toDoublyLinkedRing>`_
  ## or `newDoublyLinkedRingWith() <#newDoublyLinkedRingWith>`_
  discard

proc newDoublyLinkedNode*[T](value: T): DoublyLinkedNode[T] =
  ## Creates a new doubly linked node with the given ``value``.
  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): SinglyLinkedNode[T] =
  ## Creates a new singly linked node with the given ``value``.
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

template nodesListImpl() {.dirty.} =
  var it = L.head
  while it != nil:
    var nxt = it.next
    yield it
    it = nxt

template nodesRingImpl() {.dirty.} =
  var it = L.head
  if it != nil:
    while true:
      var nxt = it.next
      yield it
      it = nxt
      if it == L.head: break

template findImpl() {.dirty.} =
  for x in nodes(L):
    if x.value == value: return x

template pairsListImpl() {.dirty.} =
  var
    it = L.head
    i = 0
  while it != nil:
    yield (i, it.value)
    inc i
    it = it.next

template pairsRingImpl() {.dirty.} =
  var
    it = L.head
    i = 0
  if it != nil:
    while true:
      yield (i, it.value)
      inc i
      it = it.next
      if it == L.head: break

iterator items*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T]): T =
  ## yields every value of ``L``.
  itemsListImpl()

iterator items*[T](L: SinglyLinkedRing[T] | DoublyLinkedRing[T]): T =
  ## yields every value of ``L``.
  itemsRingImpl()

iterator mitems*[T](L: var SinglyLinkedList[T] |
                   var DoublyLinkedList[T]): var T =
  ## yields every value of ``L`` so that you can modify it.
  itemsListImpl()

iterator mitems*[T](L: var SinglyLinkedRing[T] |
                   var DoublyLinkedRing[T]): var T =
  ## yields every value of ``L`` so that you can modify it.
  itemsRingImpl()

iterator pairs*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T]):
                  tuple[count: int, value: T] {.inline.} =
  ## yields every ``value`` of ``L`` as ``(count, value)``.
  pairsListImpl()

iterator pairs*[T](L: SinglyLinkedRing[T] | DoublyLinkedRing[T]):
                  tuple[count: int, value: T] {.inline.} =
  ## yields a every ``value`` of ``L`` as ``(count, value)``.
  pairsRingImpl()

iterator mpairs*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T]):
                   tuple[count: int, value: var T] {.inline.} =
  ## yields every ``value`` of ``L`` for modification as
  ## ``(count, var value)``.
  pairsListImpl()

iterator mpairs*[T](L: SinglyLinkedRing[T] | DoublyLinkedRing[T]):
                   tuple[count: int, value: var T] {.inline.} =
  ## yields every ``value`` of ``L`` for modification as
  ## ``(count, var value)``.
  pairsRingImpl()

iterator nodes*[T](L: SinglyLinkedList[T]): SinglyLinkedNode[T] =
  ## iterates over every node of ``L``. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: DoublyLinkedList[T]): DoublyLinkedNode[T] =
  ## iterates over every node of ``L``. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: SinglyLinkedRing[T]): SinglyLinkedNode[T] =
  ## iterates over every node of ``L``. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

iterator nodes*[T](L: DoublyLinkedRing[T]): DoublyLinkedNode[T] =
  ## iterates over every node of ``L``. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

template lenListImpl(L: untyped, res: int) {.dirty.} =
  var it = L.head
  while it != nil:
    inc res
    it = it.next

template lenRingImpl(L: untyped, res: int) {.dirty.} =
  var it = L.head
  if it != nil:
    while true:
      inc res
      it = it.next
      if it == L.head: break

proc len*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T]): int =
  ## Return the number of nodes in ``L``.  Efficiency: ``O(n)``
  lenListImpl(L, result)

proc len*[T](L: SinglyLinkedRing[T] | DoublyLinkedRing[T]): int =
  ## Return the number of nodes in ``L``.  Efficiency: ``O(n)``
  lenRingImpl(L, result)

template dollarImpl() {.dirty.} =
  result = "["
  for x in nodes(L):
    if result.len > 1: result.add(", ")
    result.add($x.value)
  result.add("]")

proc `$`*[T](L: SinglyLinkedList[T]): string =
  ## Returns the string representation of ``L``.
  dollarImpl()

proc `$`*[T](L: DoublyLinkedList[T]): string =
  ## Returns the string representation of ``L``.
  dollarImpl()

proc `$`*[T](L: SinglyLinkedRing[T]): string =
  ## Returns the string representation of ``L``.
  dollarImpl()

proc `$`*[T](L: DoublyLinkedRing[T]): string =
  ## Returns the string representation of ``L``.
  dollarImpl()

proc find*[T](L: SinglyLinkedList[T], value: T): SinglyLinkedNode[T] =
  ## Searches in the list ``L`` for ``value``.
  ##
  ## Returns ``nil`` if ``value`` does not exist.
  findImpl()

proc find*[T](L: DoublyLinkedList[T], value: T): DoublyLinkedNode[T] =
  ## Searches in the list ``L`` for ``value``.
  ##
  ## Returns ``nil`` if ``value`` does not exist.
  findImpl()

proc find*[T](L: SinglyLinkedRing[T], value: T): SinglyLinkedNode[T] =
  ## Searches in the ring ``L`` for ``value``.
  ##
  ## Returns ``nil`` if ``value`` does not exist.
  findImpl()

proc find*[T](L: DoublyLinkedRing[T], value: T): DoublyLinkedNode[T] =
  ## Searches in the ring ``L`` for ``value``.
  ##
  ## Returns ``nil`` if ``value`` does not exist.
  findImpl()

iterator findAll*[T](L: SinglyLinkedList[T] | SinglyLinkedRing[T],
                    value: T): SinglyLinkedNode[T] =
  ## Iterates over ``L`` and returns all nodes matching ``value``.
  for n in nodes(L):
    if n.value == value: yield(n)

iterator findAll*[T](L: DoublyLinkedList[T] | DoublyLinkedRing[T],
                    value: T): DoublyLinkedNode[T] =
  ## Iterates over ``L`` and returns all nodes matching ``value``.
  for n in nodes(L):
    if n.value == value: yield(n)

proc contains*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T] |
                 SinglyLinkedRing[T] | DoublyLinkedRing[T],
                 value: T): bool {.inline.} =
  ## Searches in ``L`` for ``value``.
  ##
  ## Returns ``false`` if the value does not exist, ``true`` otherwise.
  result = find(L, value) != nil

#--
#-- SLL; prepend/append/remove/removeAll
#--

proc prepend*[T](L: var SinglyLinkedList[T],
                 n: SinglyLinkedNode[T]) {.inline.} =
  ## Prepends node ``n`` to ``L``. Efficiency: ``O(1)``.
  n.next = L.head
  L.head = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Prepends node ``n`` to `L`. Efficiency: ``O(1)``.
  prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var SinglyLinkedList[T],
                 n: SinglyLinkedNode[T]) {.inline.} =
  ## Appends a node `n` to ``L``. Efficiency: ``O(1)``.
  n.next = nil
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Prepends a node with a ``value`` to ``L``. Efficiency: ``O(1)``.
  append(L, newSinglyLinkedNode(value))

proc remove*[T](L: var SinglyLinkedList[T], n: SinglyLinkedNode[T]) =
  ## Removes ``n`` from ``L``. Efficiency: ``O(n)``.
  if L.head == n:
    L.head = n.next
  else:
    var p = L.head
    while p != nil:
      if p.next == n:
        p.next = n.next
        return
      p = p.next

proc remove*[T](L: var SinglyLinkedList[T], value: T) =
  ## Removes the first node from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  if L.head.value == value:
    L.head = L.head.next
  else:
    var p = L.head
    while p != nil and p.next != nil:
      if p.next.value == value:
        p.next = p.next.next
        return
      p = p.next

proc removeAll*[T](L: var SinglyLinkedList[T], value: T) =
  ## Removes all nodes  from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  if L.head.value == value:
    L.head = L.head.next
    L.removeAll(value)
  else:
    var p = L.head
    while p != nil and p.next != nil:
      if p.next.value == value:
        p.next = p.next.next
      else:
        p = p.next

#--
#-- DLL; append/prepend/remove
#--

proc append*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Appends node ``n`` to ``L``. Efficiency: ``O(1)``.
  n.next = nil
  n.prev = L.tail
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var DoublyLinkedList[T], value: T) =
  ## Appends ``value`` to ``L``. Efficiency: ``O(1)``.
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Prepends node ``n`` to ``L``. Efficiency: ``O(1)``.
  n.prev = nil
  n.next = L.head
  if L.head != nil:
    assert(L.head.prev == nil)
    L.head.prev = n
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var DoublyLinkedList[T], value: T) =
  ## Prepends ``value`` to ``L``. Efficiency: ``O(1)``.
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Removes ``n`` from ``L``. Efficiency: ``O(1)``.
  if n == L.tail: L.tail = n.prev
  if n == L.head: L.head = n.next
  if n.next != nil: n.next.prev = n.prev
  if n.prev != nil: n.prev.next = n.next

proc remove*[T](L: var DoublyLinkedList[T], value: T) =
  ## Removes the first node  from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  L.remove(L.find(value))

proc removeAll*[T](L: var DoublyLinkedList[T], value: T) =
  ## Removes all nodes  from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  for n in L.nodes:
    if n.value == value: L.remove(n)

#--
#-- SLR: append/prepend/remove/removeAll
#--

proc append*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Appends node ``n`` to ``L``. Efficiency: ``O(1)``.
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
  ## Appends ``value`` to ``L``. Efficiency: ``O(1)``.
  append(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Prepends node ``n`` to ``L``. Efficiency: ``O(1)``.
  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
  else:
    n.next = n
    L.tail = n
  L.head = n

proc prepend*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Prepends ``value`` to ``L``. Efficiency: ``O(1)``.
  prepend(L, newSinglyLinkedNode(value))

proc remove*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Removes node ``n`` from ``L``. Efficiency: ``O(n)``.
  if L.head == n:
    L.head = n.next
    if L.tail == n: L.tail = L.head
  else:
    var p = L.head
    while p != nil:
      if p.next == n:
        p.next = n.next
        if L.tail == n: L.tail = p
        return

proc remove*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Removes the first node from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  if L.head.value == value:
    if L.tail == L.head: L.tail = L.head.next
    L.head = L.head.next
  else:
    var p = L.head
    while p != nil and p.next != nil:
      if p.next.value == value:
        if L.tail == p.next: L.tail = p
        p.next = p.next.next
        return

proc removeAll*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Removes all nodes from ``L`` with a matching ``value``. Efficiency: ``O(n)``.
  if L.head.value == value:
    if L.tail == L.head: L.tail = L.head.next
    L.head = L.head.next
    L.removeAll(value)
  else:
    var p = L.head
    while p != nil and p.next != L.head:
      if p.next.value == value:
        if L.tail == p.next: L.tail = p
        p.next = p.next.next
      else:
        p = p.next

#--
#-- DLR: append/prepend/remove/removeAll
#--

proc append*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Appends node ``n`` to ``L``. Efficiency: ``O(1)``.
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
  ## Appends ``value`` to ``L``. Efficiency: ``O(1)``.
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Prepends node ``n`` to ``L``. Efficiency: ``O(1)``.
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
  ## Prepends ``value`` to ``L``. Efficiency: ``O(1)``.
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Removes a node ``n`` from ``L``. Efficiency: ``O(1)``.
  n.next.prev = n.prev
  n.prev.next = n.next
  if n == L.head:
    var p = L.head.prev
    if p == L.head:
      # only one element left:
      L.head = nil
    else:
      L.head = L.head.next

proc remove*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Removes the first node  from ``L`` with a matching ``value``. Efficiency: ``O(1)``.
  L.remove(L.find(value))

proc removeAll*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Removes all nodes from ``L`` with a matching ``value``.
  ## Efficiency: ``O(n)``.

  # can't use nodes() iterator as it causes infinite loop
  var n = L.head
  while n != nil:
    let nxt = n.next
    if n.value == value:
      L.remove(n)
      n = nxt.prev
    else:
      n = nxt
    if n == L.head: break

proc `==`*[T](a, b: SinglyLinkedList[T]): bool {.inline.} =
  ## Return ``true`` if the elements and their order match.  Efficiency: ``O(n)``
  var
    p: SinglyLinkedNode[T] = b.head
    i = 0
  for v in a.items:
    if i > 0 and p == nil: return
    if p.value != v: return
    p = p.next
    inc i
  if p == nil: result = true

proc `==`*[T](a, b: SinglyLinkedRing[T]): bool {.inline.} =
  ## Return ``true`` if the elements and their order match.  Efficiency: ``O(n)``
  var
    p: SinglyLinkedNode[T] = b.head
    i = 0
  for v in a.items:
    if i > 0 and p == b.tail.next: return
    if p.value != v: return
    p = p.next
    inc i
  if p == b.tail.next: result = true

proc `==`*[T](a, b: DoublyLinkedList[T]): bool {.inline.} =
  ## Return ``true`` if the elements and their order match.  Efficiency: ``O(n)``
  var
    p: DoublyLinkedNode[T] = b.head
    i = 0
  for v in a.items:
    if i > 0 and p == nil: return
    if p.value != v: return
    p = p.next
    inc i
  if p == nil: result = true

proc `==`*[T](a, b: DoublyLinkedRing[T]): bool {.inline.} =
  ## Return ``true`` if the elements and their order match.  Efficiency: ``O(n)``
  var
    p: DoublyLinkedNode[T] = b.head
    i = 0
  for v in a.items:
    if i > 0 and p == b.head: return
    if p.value != v: return
    p = p.next
    inc i
  if p == b.head: result = true

proc toSeq*[T](L: SinglyLinkedList[T] | DoublyLinkedList[T] |
              SinglyLinkedRing[T] | DoublyLinkedRing[T] ): seq[T] =
  ## Return a sequence containing a copy of the elements of ``L``.  Efficiency: ``O(n)``.
  result = @[]
  for v in L.items:
    result.add(v)

template toListImpl(s, res: untyped) =
  for v in s: res.append(v)

proc toSinglyLinkedList*[T](s: seq[T]): SinglyLinkedList[T] =
  ## Return a SinglyLinkedList containing a copy of the elements from ``s``
  result = initSinglyLinkedList[T]()
  toListImpl(s, result)

proc toDoublyLinkedList*[T](s: openArray[T]): DoublyLinkedList[T] =
  ## Return a DoublyLinkedList containing a copy of the elements from ``s``
  result = initDoublyLinkedList[T]()
  toListImpl(s, result)

proc toSinglyLinkedRing*[T](s: openArray[T]): SinglyLinkedRing[T] =
  ## Return a SinglyLinkedRing containing a copy of the elements from ``s``
  result = initSinglyLinkedRing[T]()
  toListImpl(s, result)

proc toDoublyLinkedRing*[T](s: openArray[T]): DoublyLinkedRing[T] =
  ## Return a DoublyLinkedRing containing a copy of the elements from ``s``
  result = initDoublyLinkedRing[T]()
  toListImpl(s, result)

proc map*[T, S](lst: SinglyLinkedList[T],
               op: proc (x: T): S {.closure.}): SinglyLinkedList[S] =
  ## Returns a new SinglyLinkedList with the results of ``op`` applied to every item in
  ## ``lst``.
  ##
  ## Since the input is not modified, you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence.
  result = initSinglyLinkedList[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: DoublyLinkedList[T],
               op: proc (x: T): S {.closure.}): DoublyLinkedList[S] =
  ## Returns a new DoublyLinkedList with the results of ``op`` applied to every item in
  ## ``lst``.
  ##
  ## Since the input is not modified, you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence.
  result = initDoublyLinkedList[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: SinglyLinkedRing[T],
               op: proc (x: T): S {.closure.}): SinglyLinkedRing[S] =
  ## Returns a new SinglyLinkedRing with the results of ``op`` applied to every item in
  ## ``lst``.
  ##
  ## Since the input is not modified, you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence.
  result = initSinglyLinkedRing[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: DoublyLinkedRing[T],
               op: proc (x: T): S {.closure.}): DoublyLinkedRing[S] =
  ## Returns a new DoublyLinkedRing with the results of ``op`` applied to every item in
  ## ``lst``.
  ##
  ## Since the input is not modified, you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence.
  result = initDoublyLinkedRing[S]()
  for x in lst.items():
    result.append(op(x))

proc apply*[T](lst: var SinglyLinkedList[T], op: proc (x: var T) {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  for v in lst.mitems: op(v)

proc apply*[T](lst: var DoublyLinkedList[T], op: proc (x: var T) {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  for v in lst.mitems: op(v)

proc apply*[T](lst: var SinglyLinkedRing[T], op: proc (x: var T) {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  for v in lst.mitems: op(v)

proc apply*[T](lst: var DoublyLinkedRing[T], op: proc (x: var T) {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  for v in lst.mitems: op(v)

proc apply*[T](lst: var SinglyLinkedList[T], op: proc (x: T): T {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var DoublyLinkedList[T], op: proc (x: T): T {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var SinglyLinkedRing[T], op: proc (x: T): T {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var DoublyLinkedRing[T], op: proc (x: T): T {.closure.}) =
  ## Applies ``op`` to every item in ``lst`` by modifying ``lst`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  for v in lst.mitems: v = op(v)

template newSinglyLinkedListWith*(len: int, init: untyped): untyped =
  ## Creates a new SinglyLinkedList, calling ``init`` to initialize each value.
  var result = initSinglyLinkedList[type(init)]()
  for i in 0 .. <len:
    result.append(init)
  result

template newDoublyLinkedListWith*(len: int, init: untyped): untyped =
  ## Creates a new DoublyLinkedList, calling ``init`` to initialize each value.
  var result = initDoublyLinkedList[type(init)]()
  for i in 0 .. <len:
    result.append(init)
  result

template newSinglyLinkedRingWith*(len: int, init: untyped): untyped =
  ## Creates a new SinglyLinkedRing, calling ``init`` to initialize each value.
  var result = initSinglyLinkedRing[type(init)]()
  for i in 0 .. <len:
    result.append(init)
  result

template newDoublyLinkedRingWith*(len: int, init: untyped): untyped =
  ## Creates a new DoublyLinkedRing, calling ``init`` to initialize each value.
  var result = initDoublyLinkedRing[type(init)]()
  for i in 0 .. <len:
    result.append(init)
  result

when isMainModule:
  when defined(doc) or defined(doc2): discard
  else:
    from random import random

  var
    # totoSinglyLinkedList(), .....

    sll = @[1, 2, 3, 4].toSinglyLinkedList()
    dll = @[1, 2, 3, 4].toDoublyLinkedList()
    slr = @[1, 2, 3, 4].toSinglyLinkedRing()
    dlr = @[1, 2, 3, 4].toDoublyLinkedRing()

    # map()
    sllm = map(sll, proc(x: int): string = $x)
    dllm = map(dll, proc(x: int): string = $x)
    slrm = map(slr, proc(x: int): string = $x)
    dlrm = map(dlr, proc(x: int): string = $x)

  block:  # items/mitems
    var acc: seq[int]
    acc = @[]
    for x in dll.items:
      acc.add(x)
    doAssert(acc == dll.toSeq)
    acc = @[]
    for x in dll.items:
      acc.add(x)
    doAssert(acc == dll.toSeq)
    acc = @[]
    for x in slr.items:
      acc.add(x)
    doAssert(acc == slr.toSeq)
    acc = @[]
    for x in dlr.items:
      acc.add(x)
    doAssert(acc == dlr.toSeq)

    var
      sll2 = @[1, 2, 3, 4].toSinglyLinkedList()
      dll2 = @[1, 2, 3, 4].toDoublyLinkedList()
      slr2 = @[1, 2, 3, 4].toSinglyLinkedRing()
      dlr2 = @[1, 2, 3, 4].toDoublyLinkedRing()

    for x in sll2.mitems:
      x = 1
    doAssert(@[1,1,1,1] == sll2.toSeq)
    for x in dll2.mitems:
      x = 1
    doAssert(@[1,1,1,1] == dll2.toSeq)
    for x in slr2.mitems:
      x = 1
    doAssert(@[1,1,1,1] == slr2.toSeq)
    for x in dlr2.mitems:
      x = 1
    doAssert(@[1,1,1,1] == dlr2.toSeq)

  block:  # pairs/mpairs
    var
      acc: seq[int]
      acc2: seq[int]
    acc = @[]
    acc2 = @[]
    for x in dll.pairs:
      acc.add(x.count)
      acc2.add(x.value)
    doAssert(acc == @[0,1,2,3])
    doAssert(acc2 == dll.toSeq)
    acc = @[]
    acc2 = @[]
    for x in dll.pairs:
      acc.add(x.count)
      acc2.add(x.value)
    doAssert(acc == @[0,1,2,3])
    doAssert(acc2 == dll.toSeq)
    acc = @[]
    acc2 = @[]
    for x in slr.pairs:
      acc.add(x.count)
      acc2.add(x.value)
    doAssert(acc == @[0,1,2,3])
    doAssert(acc2 == slr.toSeq)
    acc = @[]
    acc2 = @[]
    for x in dlr.pairs:
      acc.add(x.count)
      acc2.add(x.value)
    doAssert(acc == @[0,1,2,3])
    doAssert(acc2 == dlr.toSeq)

    var
      sll2 = @[1, 2, 3, 4].toSinglyLinkedList()
      dll2 = @[1, 2, 3, 4].toDoublyLinkedList()
      slr2 = @[1, 2, 3, 4].toSinglyLinkedRing()
      dlr2 = @[1, 2, 3, 4].toDoublyLinkedRing()

    for i,x in sll2.mpairs:
      x = 1
    doAssert(@[1,1,1,1] == sll2.toSeq)
    for i,x in dll2.mpairs:
      x = 1
    doAssert(@[1,1,1,1] == dll2.toSeq)
    for i,x in slr2.mpairs:
      x = 1
    doAssert(@[1,1,1,1] == slr2.toSeq)
    for i,x in dlr2.mpairs:
      x = 1
    doAssert(@[1,1,1,1] == dlr2.toSeq)

  block:  # `==`  SinglyLinkedLists
    var
      a1 = @[1, 2, 3, 4].toSinglyLinkedList()
      a2 = @[1, 2, 3].toSinglyLinkedList()
      b1 = @[1, 2, 3].toSinglyLinkedList()
      b2 = @[1, 2, 4].toSinglyLinkedList()
    doAssert(not (a1 == a2))
    doAssert(not (a2 == a1))
    doAssert(a1 != a2)
    doAssert(a2 != a1)
    doAssert(not (b1 == b2))
    doAssert(not (b2 == b1))
    doAssert(b1 != b2)
    doAssert(b2 != b1)

  block:  # `==`  DoublyLinkedLists
    var
      a1 = @[1, 2, 3, 4].toDoublyLinkedList()
      a2 = @[1, 2, 3].toDoublyLinkedList()
      b1 = @[1, 2, 3].toDoublyLinkedList()
      b2 = @[1, 2, 4].toDoublyLinkedList()
    doAssert(not (a1 == a2))
    doAssert(not (a2 == a1))
    doAssert(a1 != a2)
    doAssert(a2 != a1)
    doAssert(not (b1 == b2))
    doAssert(not (b2 == b1))
    doAssert(b1 != b2)
    doAssert(b2 != b1)

  block:  # `==`  SinglyLinkedRings
    var
      a1 = @[1, 2, 3, 4].toSinglyLinkedRing()
      a2 = @[1, 2, 3].toSinglyLinkedRing()
      b1 = @[1, 2, 3].toSinglyLinkedRing()
      b2 = @[1, 2, 4].toSinglyLinkedRing()
    doAssert(not (a1 == a2))
    doAssert(not (a2 == a1))
    doAssert(a1 != a2)
    doAssert(a2 != a1)
    doAssert(not (b1 == b2))
    doAssert(not (b2 == b1))
    doAssert(b1 != b2)
    doAssert(b2 != b1)

  block:  # `==`  DoublyLinkedRings
    var
      a1 = @[1, 2, 3, 4].toDoublyLinkedRing()
      a2 = @[1, 2, 3].toDoublyLinkedRing()
      b1 = @[1, 2, 3].toDoublyLinkedRing()
      b2 = @[1, 2, 4].toDoublyLinkedRing()
    doAssert(not (a1 == a2))
    doAssert(not (a2 == a1))
    doAssert(a1 != a2)
    doAssert(a2 != a1)
    doAssert(not (b1 == b2))
    doAssert(not (b2 == b1))
    doAssert(b1 != b2)
    doAssert(b2 != b1)

  block:  # toSeq()
    doAssert @[1,3,2,4].toSinglyLinkedList() == @[1,3,2,4].toSinglyLinkedList()
    doAssert sllm.toSeq() == @["1", "2", "3", "4"]
    doAssert sllm == toSinglyLinkedList(@["1", "2", "3", "4"])
    doAssert dllm.toSeq() == @["1", "2", "3", "4"]
    doAssert dllm == toDoublyLinkedList(@["1", "2", "3", "4"])
    doAssert slrm.toSeq() == @["1", "2", "3", "4"]
    doAssert slrm == toSinglyLinkedRing(@["1", "2", "3", "4"])
    doAssert dlrm.toSeq() == @["1", "2", "3", "4"]
    doAssert dlrm == toDoublyLinkedRing(@["1", "2", "3", "4"])

  block:  # apply( var T )
    sll.apply(proc(x: var int) = (x *= 2))
    doAssert sll == @[2,4,6,8].toSinglyLinkedList()
    sll.remove(4)
    doAssert sll == @[2,6,8].toSinglyLinkedList()
    sll.append(2)
    sll.removeAll(2)
    doAssert sll == @[6,8].toSinglyLinkedList()

    slr.apply(proc(x: var int) = (x *= 2))
    doAssert slr == @[2,4,6,8].toSinglyLinkedRing()
    slr.remove(4)
    doAssert slr == @[2,6,8].toSinglyLinkedRing()
    slr.append(2)
    slr.removeAll(2)
    doAssert slr == @[6,8].toSinglyLinkedRing()

    dll.apply(proc(x: var int) = (x *= 2))
    doAssert dll == @[2,4,6,8].toDoublyLinkedList()
    dll.remove(4)
    doAssert dll == @[2,6,8].toDoublyLinkedList()
    dll.append(2)
    dll.removeAll(2)
    doAssert dll == @[6,8].toDoublyLinkedList()

    dlr.apply(proc(x: var int) = (x *= 2))
    doAssert dlr == @[2,4,6,8].toDoublyLinkedRing()
    dlr.remove(4)
    doAssert dlr == @[2,6,8].toDoublyLinkedRing()
    dlr.append(2)
    dlr.removeAll(2)
    doAssert dlr == @[6,8].toDoublyLinkedRing()

  block:  # apply( T: T )
    sll.prepend(4); sll.prepend(2)
    sll.apply(proc(x: int): int = (1*x))
    doAssert sll == @[2,4,6,8].toSinglyLinkedList()
    sll.remove(4)
    doAssert sll == @[2,6,8].toSinglyLinkedList()
    sll.append(2)
    sll.removeAll(2)
    doAssert sll == @[6,8].toSinglyLinkedList()

    slr.prepend(4); slr.prepend(2)
    slr.apply(proc(x: int): int = (1*x))
    doAssert slr == @[2,4,6,8].toSinglyLinkedRing()
    slr.remove(4)
    doAssert slr == @[2,6,8].toSinglyLinkedRing()
    slr.append(2)
    slr.removeAll(2)
    doAssert slr == @[6,8].toSinglyLinkedRing()

    dll.prepend(4); dll.prepend(2)
    dll.apply(proc(x: int): int = (1*x))
    doAssert dll == @[2,4,6,8].toDoublyLinkedList()
    dll.remove(4)
    doAssert dll == @[2,6,8].toDoublyLinkedList()
    dll.append(2)
    dll.removeAll(2)
    doAssert dll == @[6,8].toDoublyLinkedList()

    dlr.prepend(4); dlr.prepend(2)
    dlr.apply(proc(x: int): int = (1*x))
    doAssert dlr == @[2,4,6,8].toDoublyLinkedRing()
    dlr.remove(4)
    doAssert dlr == @[2,6,8].toDoublyLinkedRing()
    dlr.append(2)
    dlr.removeAll(2)
    doAssert dlr == @[6,8].toDoublyLinkedRing()

  blocK:  # findAll()
    var c = 0
    sll.prepend(2); sll.prepend(4); sll.prepend(2)
    for n in sll.findAll(2): c += n.value
    doAssert c == 4

    c = 0
    dll.prepend(2); dll.prepend(4); dll.prepend(2)
    for n in dll.findAll(2): c += n.value
    doAssert c == 4

    c = 0
    slr.prepend(2); slr.prepend(4); slr.prepend(2)
    for n in slr.findAll(2): c += n.value
    doAssert c == 4

    c = 0
    dlr.prepend(2); dlr.prepend(4); dlr.prepend(2)
    for n in dlr.findAll(2): c += n.value
    doAssert c == 4

  block:  # newSinglyLinkedList
    var
      sllRand = newSinglyLinkedListWith(10, random(10))
      c = 0
    doAssert sllRand.toSeq().len == 10
    for v in sllRand.items: c += v
    doAssert c != 0

  block:  # newDoublyLinkedList
    var
      dllRand = newDoublyLinkedListWith(10, random(10))
      c = 0
    doAssert dllRand.toSeq().len == 10
    for v in dllRand.items: c += v
    doAssert c != 0

  block:  # newSinglyLinkedRing
    var
      slrRand = newSinglyLinkedRingWith(10, random(10))
      c = 0
    doAssert slrRand.toSeq().len == 10
    for v in slrRand.items: c += v
    doAssert c != 0

  block:  # newDoublyLinkedRing
    var
      dlrRand = newDoublyLinkedRingWith(10, random(10))
      c = 0
    doAssert dlrRand.toSeq().len == 10
    for v in dlrRand.items: c += v
    doAssert c != 0

  block:  # len()
    var
      sllRand = newSinglyLinkedListWith(10, random(10))
      dllRand = newDoublyLinkedListWith(10, random(10))
      slrRand = newSinglyLinkedRingWith(10, random(10))
      dlrRand = newDoublyLinkedRingWith(10, random(10))
    doAssert(sllRand.len == 10)
    doAssert(dllRand.len == 10)
    doAssert(slrRand.len == 10)
    doAssert(dlrRand.len == 10)
