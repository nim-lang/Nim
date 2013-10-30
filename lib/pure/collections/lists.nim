#
#
#            Nimrod's Runtime Library
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
  TDoublyLinkedNode* {.pure,
      final.}[T] = object ## a node a doubly linked list consists of
    next*, prev*: ref TDoublyLinkedNode[T]
    value*: T
  PDoublyLinkedNode*[T] = ref TDoublyLinkedNode[T]

  TSinglyLinkedNode* {.pure,
      final.}[T] = object ## a node a singly linked list consists of
    next*: ref TSinglyLinkedNode[T]
    value*: T
  PSinglyLinkedNode*[T] = ref TSinglyLinkedNode[T]

  TSinglyLinkedList* {.pure, final.}[T] = object ## a singly linked list
    head*, tail*: PSinglyLinkedNode[T]

  TDoublyLinkedList* {.pure, final.}[T] = object ## a doubly linked list
    head*, tail*: PDoublyLinkedNode[T]

  TSinglyLinkedRing* {.pure, final.}[T] = object ## a singly linked ring
    head*: PSinglyLinkedNode[T]

  TDoublyLinkedRing* {.pure, final.}[T] = object ## a doubly linked ring
    head*: PDoublyLinkedNode[T]

proc initSinglyLinkedList*[T](): TSinglyLinkedList[T] =
  ## creates a new singly linked list that is empty.
  nil

proc initDoublyLinkedList*[T](): TDoublyLinkedList[T] =
  ## creates a new doubly linked list that is empty.
  nil

proc initSinglyLinkedRing*[T](): TSinglyLinkedRing[T] =
  ## creates a new singly linked ring that is empty.
  nil

proc initDoublyLinkedRing*[T](): TDoublyLinkedRing[T] =
  ## creates a new doubly linked ring that is empty.
  nil

proc newDoublyLinkedNode*[T](value: T): PDoublyLinkedNode[T] =
  ## creates a new doubly linked node with the given `value`.
  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): PSinglyLinkedNode[T] =
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

iterator items*[T](L: TDoublyLinkedList[T]): T =
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: TSinglyLinkedList[T]): T =
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: TSinglyLinkedRing[T]): T =
  ## yields every value of `L`.
  itemsRingImpl()

iterator items*[T](L: TDoublyLinkedRing[T]): T =
  ## yields every value of `L`.
  itemsRingImpl()

iterator nodes*[T](L: TSinglyLinkedList[T]): PSinglyLinkedNode[T] =
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: TDoublyLinkedList[T]): PDoublyLinkedNode[T] =
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesListImpl()

iterator nodes*[T](L: TSinglyLinkedRing[T]): PSinglyLinkedNode[T] =
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

iterator nodes*[T](L: TDoublyLinkedRing[T]): PDoublyLinkedNode[T] =
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  nodesRingImpl()

template dollarImpl() {.dirty.} =
  result = "["
  for x in nodes(L):
    if result.len > 1: result.add(", ")
    result.add($x.value)
  result.add("]")

proc `$`*[T](L: TSinglyLinkedList[T]): string =
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: TDoublyLinkedList[T]): string =
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: TSinglyLinkedRing[T]): string =
  ## turns a list into its string representation.
  dollarImpl()

proc `$`*[T](L: TDoublyLinkedRing[T]): string =
  ## turns a list into its string representation.
  dollarImpl()

proc find*[T](L: TSinglyLinkedList[T], value: T): PSinglyLinkedNode[T] =
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: TDoublyLinkedList[T], value: T): PDoublyLinkedNode[T] =
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: TSinglyLinkedRing[T], value: T): PSinglyLinkedNode[T] =
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc find*[T](L: TDoublyLinkedRing[T], value: T): PDoublyLinkedNode[T] =
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  findImpl()

proc contains*[T](L: TSinglyLinkedList[T], value: T): bool {.inline.} =
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: TDoublyLinkedList[T], value: T): bool {.inline.} =
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: TSinglyLinkedRing[T], value: T): bool {.inline.} =
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc contains*[T](L: TDoublyLinkedRing[T], value: T): bool {.inline.} =
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  result = find(L, value) != nil

proc prepend*[T](L: var TSinglyLinkedList[T],
                 n: PSinglyLinkedNode[T]) {.inline.} =
  ## prepends a node to `L`. Efficiency: O(1).
  n.next = L.head
  L.head = n

proc prepend*[T](L: var TSinglyLinkedList[T], value: T) {.inline.} =
  ## prepends a node to `L`. Efficiency: O(1).
  prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var TDoublyLinkedList[T], n: PDoublyLinkedNode[T]) =
  ## appends a node `n` to `L`. Efficiency: O(1).
  n.next = nil
  n.prev = L.tail
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var TDoublyLinkedList[T], value: T) =
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var TDoublyLinkedList[T], n: PDoublyLinkedNode[T]) =
  ## prepends a node `n` to `L`. Efficiency: O(1).
  n.prev = nil
  n.next = L.head
  if L.head != nil:
    assert(L.head.prev == nil)
    L.head.prev = n
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var TDoublyLinkedList[T], value: T) =
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var TDoublyLinkedList[T], n: PDoublyLinkedNode[T]) =
  ## removes `n` from `L`. Efficiency: O(1).
  if n == L.tail: L.tail = n.prev
  if n == L.head: L.head = n.next
  if n.next != nil: n.next.prev = n.prev
  if n.prev != nil: n.prev.next = n.next


proc prepend*[T](L: var TSinglyLinkedRing[T], n: PSinglyLinkedNode[T]) =
  ## prepends a node `n` to `L`. Efficiency: O(1).
  if L.head != nil:
    n.next = L.head
    L.head.next = n
  else:
    n.next = n
  L.head = n

proc prepend*[T](L: var TSinglyLinkedRing[T], value: T) =
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var TDoublyLinkedRing[T], n: PDoublyLinkedNode[T]) =
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

proc append*[T](L: var TDoublyLinkedRing[T], value: T) =
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var TDoublyLinkedRing[T], n: PDoublyLinkedNode[T]) =
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

proc prepend*[T](L: var TDoublyLinkedRing[T], value: T) =
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var TDoublyLinkedRing[T], n: PDoublyLinkedNode[T]) =
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


