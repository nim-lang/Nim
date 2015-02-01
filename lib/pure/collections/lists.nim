#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of singly and doubly linked lists. Because it makes no sense
## to do so, the 'next' and 'prev' pointers are not hidden from you and can
## be manipulated directly for efficiency.

when not defined(nimhygiene):
  {.pragma: dirty.}

type
  DoublyLinkedNodeObj*[T] = object ## a node a doubly linked list consists of
    next*, prev*: ref DoublyLinkedNodeObj[T]
    value*: T
  DoublyLinkedNode*[T] = ref DoublyLinkedNodeObj[T]

  SinglyLinkedNodeObj*[T] = object ## a node a singly linked list consists of
    next*: ref SinglyLinkedNodeObj[T]
    value*: T
  SinglyLinkedNode*[T] = ref SinglyLinkedNodeObj[T]

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
  ## creates a new singly linked list that is empty.
  discard

proc initDoublyLinkedList*[T](): DoublyLinkedList[T] =
  ## creates a new doubly linked list that is empty.
  discard

proc initSinglyLinkedRing*[T](): SinglyLinkedRing[T] =
  ## creates a new singly linked ring that is empty.
  discard

proc initDoublyLinkedRing*[T](): DoublyLinkedRing[T] =
  ## creates a new doubly linked ring that is empty.
  discard

proc newDoublyLinkedNode*[T](value: T): DoublyLinkedNode[T] =
  ## creates a new doubly linked node with the given `value`.
  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): SinglyLinkedNode[T] =
  ## creates a new singly linked node with the given `value`.
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

iterator items*[T](L: DoublyLinkedList[T]): T = 
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: SinglyLinkedList[T]): T = 
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: SinglyLinkedRing[T]): T = 
  ## yields every value of `L`.
  itemsRingImpl()

iterator items*[T](L: DoublyLinkedRing[T]): T = 
  ## yields every value of `L`.
  itemsRingImpl()

iterator mitems*[T](L: var DoublyLinkedList[T]): var T =
  ## yields every value of `L` so that you can modify it.
  itemsListImpl()

iterator mitems*[T](L: var SinglyLinkedList[T]): var T =
  ## yields every value of `L` so that you can modify it.
  itemsListImpl()

iterator mitems*[T](L: var SinglyLinkedRing[T]): var T =
  ## yields every value of `L` so that you can modify it.
  itemsRingImpl()

iterator mitems*[T](L: var DoublyLinkedRing[T]): var T =
  ## yields every value of `L` so that you can modify it.
  itemsRingImpl()

iterator nodes*[T](L: SinglyLinkedList[T]): SinglyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: DoublyLinkedList[T]): DoublyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: SinglyLinkedRing[T]): SinglyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

iterator nodes*[T](L: DoublyLinkedRing[T]): DoublyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

template dollarImpl() {.dirty.} =
  result = "["
  for x in nodes(L):
    if result.len > 1: result.add(", ")
    result.add($x.value)
  result.add("]")

proc `$`*[T](L: SinglyLinkedList[T]): string = 
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: DoublyLinkedList[T]): string = 
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: SinglyLinkedRing[T]): string = 
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: DoublyLinkedRing[T]): string = 
  ## turns a list into its string representation.
  dollarImpl()

proc find*[T](L: SinglyLinkedList[T], value: T): SinglyLinkedNode[T] = 
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: DoublyLinkedList[T], value: T): DoublyLinkedNode[T] = 
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: SinglyLinkedRing[T], value: T): SinglyLinkedNode[T] = 
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: DoublyLinkedRing[T], value: T): DoublyLinkedNode[T] = 
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc contains*[T](L: SinglyLinkedList[T], value: T): bool {.inline.} = 
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: DoublyLinkedList[T], value: T): bool {.inline.} = 
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: SinglyLinkedRing[T], value: T): bool {.inline.} = 
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: DoublyLinkedRing[T], value: T): bool {.inline.} = 
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc prepend*[T](L: var SinglyLinkedList[T], 
                 n: SinglyLinkedNode[T]) {.inline.} = 
  ## prepends a node to `L`. Efficiency: O(1).
  n.next = L.head
  L.head = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) {.inline.} = 
  ## prepends a node to `L`. Efficiency: O(1).
  prepend(L, newSinglyLinkedNode(value))
  
proc append*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) = 
  ## appends a node `n` to `L`. Efficiency: O(1).
  n.next = nil
  n.prev = L.tail
  if L.tail != nil: 
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var DoublyLinkedList[T], value: T) = 
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) = 
  ## prepends a node `n` to `L`. Efficiency: O(1).
  n.prev = nil
  n.next = L.head
  if L.head != nil:
    assert(L.head.prev == nil)
    L.head.prev = n
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var DoublyLinkedList[T], value: T) = 
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newDoublyLinkedNode(value))
  
proc remove*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) = 
  ## removes `n` from `L`. Efficiency: O(1).
  if n == L.tail: L.tail = n.prev
  if n == L.head: L.head = n.next
  if n.next != nil: n.next.prev = n.prev
  if n.prev != nil: n.prev.next = n.next


proc append*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) = 
  ## appends a node `n` to `L`. Efficiency: O(1).
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
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) = 
  ## prepends a node `n` to `L`. Efficiency: O(1).
  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
  else:
    n.next = n
    L.tail = n
  L.head = n

proc prepend*[T](L: var SinglyLinkedRing[T], value: T) = 
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) = 
  ## appends a node `n` to `L`. Efficiency: O(1).
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
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) = 
  ## prepends a node `n` to `L`. Efficiency: O(1).
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
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newDoublyLinkedNode(value))
  
proc remove*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) = 
  ## removes `n` from `L`. Efficiency: O(1).
  n.next.prev = n.prev
  n.prev.next = n.next
  if n == L.head: 
    var p = L.head.prev
    if p == L.head: 
      # only one element left:
      L.head = nil
    else:
      L.head = L.head.prev
