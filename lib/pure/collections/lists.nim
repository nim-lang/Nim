#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of singly and doubly linked lists. Because it makes no sense
## to do so, the 'next' and 'prev' pointers are not hidden from you and can
## be manipulated directly for efficiency.

type
  TDoublyLinkedNode*[T] {.pure, 
      final.} = object ## a node a doubly linked list consists of
    next*, prev*: ref TDoublyLinkedNode[T]
    value*: T
  PDoublyLinkedNode*[T] = ref TDoublyLinkedNode[T]

  TSinglyLinkedNode*[T] {.pure, 
      final.} = object ## a node a singly linked list consists of
    next*: ref TSinglyLinkedNode[T]
    value*: T
  PSinglyLinkedNode*[T] = ref TSinglyLinkedNode[T]
  
  TRingNode[T] {.pure, 
      final.} = object ## a node a ring list consists of
    next*, prev*: ref TRingNode[T]
    value*: T
    
  PRingNode*[T] = ref TRingNode[T]

proc newDoublyLinkedNode*[T](value: T): PDoublyLinkedNode[T] =
  ## creates a new doubly linked node with the given `value`.
  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): PSinglyLinkedNode[T] =
  ## creates a new singly linked node with the given `value`.
  new(result)
  result.value = value

iterator items*[T](n: PDoublyLinkedNode[T]): T = 
  ## yields every value of `x`.
  var it = n
  while it != nil:
    yield it.value
    it = it.next

iterator items*[T](n: PSinglyLinkedNode[T]): T = 
  ## yields every value of `x`.
  var it = n
  while it != nil:
    yield it.value
    it = it.next

iterator nodes*[T](n: PSinglyLinkedNode[T]): PSinglyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  var it = n
  while it != nil:
    var nxt = it.next
    yield it
    it = nxt

iterator nodes*[T](n: PDoublyLinkedNode[T]): PDoublyLinkedNode[T] = 
  ## iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  var it = n
  while it != nil:
    var nxt = it.next
    yield it
    it = nxt

proc `$`*[list: PSinglyLinkedNode|PDoublyLinkedNode](n: list): string = 
  ## turns a list into its string representation.
  result = "["
  for x in nodes(n):
    if result.len > 1: result.add(", ")
    result.add($x.value)
  result.add("]")

proc find*[list: PSinglyLinkedNode|PDoublyLinkedNode, T](
           n: list, value: T): list = 
  ## searches in the list for a value. Returns nil if the value does not
  ## exist.
  for x in nodes(n):
    if x.value == value: return x

proc contains*[list: PSinglyLinkedNode|PDoublyLinkedNode, T](
           n: list, value: T): list = 
  ## searches in the list for a value. Returns false if the value does not
  ## exist, true otherwise.
  for x in nodes(n):
    if x.value == value: return true

proc prepend*[T](head: var PSinglyLinkedNode[T], 
                 toAdd: PSinglyLinkedNode[T]) {.inline.} = 
  ## prepends a node to `head`. Efficiency: O(1).
  toAdd.next = head
  head = toAdd

proc prepend*[T](head: var PSinglyLinkedNode[T], x: T) {.inline.} = 
  ## creates a new node with the value `x` and prepends that node to `head`.
  ## Efficiency: O(1).
  preprend(head, newSinglyLinkedNode(x))

proc append*[T](head: var PSinglyLinkedNode[T], 
                toAdd: PSinglyLinkedNode[T]) = 
  ## appends a node to `head`. Efficiency: O(n).
  if head == nil:
    head = toAdd
  else:
    var it = head
    while it.next != nil: it = it.next
    it.next = toAdd

proc append*[T](head: var PSinglyLinkedNode[T], x: T) {.inline.} = 
  ## creates a new node with the value `x` and appends that node to `head`.
  ## Efficiency: O(n).
  append(head, newSinglyLinkedNode(x))


proc prepend*[T](head: var PDoublyLinkedNode[T], 
                 toAdd: PDoublyLinkedNode[T]) {.inline.} = 
  ## prepends a node to `head`. Efficiency: O(1).
  if head == nil:
    head = toAdd
    # head.prev stores the last node:
    head.prev = toAdd
  else:
    toAdd.next = head
    toAdd.prev = head.prev # copy pointer to last element
    head.prev = toAdd
    head = toAdd

proc prepend*[T](head: var PDoublyLinkedNode[T], x: T) {.inline.} = 
  ## creates a new node with the value `x` and prepends that node to `head`.
  ## Efficiency: O(1).
  preprend(head, newDoublyLinkedNode(x))

proc append*[T](head: var PDoublyLinkedNode[T], 
                toAdd: PDoublyLinkedNode[T]) {.inline.} = 
  ## appends a node to `head`. Efficiency: O(1).
  if head == nil:
    head = toAdd
    # head.prev stores the last node:
    head.prev = toAdd
  else:
    var last = head.prev
    assert last.next == nil
    last.next = toAdd
    toAdd.prev = last
    head.prev = toAdd # new last element

proc append*[T](head: var PDoublyLinkedNode[T], x: T) {.inline.} = 
  ## creates a new node with the value `x` and appends that node to `head`.
  ## Efficiency: O(1).
  append(head, newDoublyLinkedNode(x))




