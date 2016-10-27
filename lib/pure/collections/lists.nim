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
##
## `DoublyLinkedList` and `DoublyLinkedRing` are Efficiency: O(1) to `remove` elements
## (O(n) to find, O(1) to remove)
##
## `SinglyLinkedList` and `SingleLinkedRing` are O(n) to `remove` elements
## (O(n^2) as O(n) to find, O(n) to remove)
## so only used these when slow removal of values is acceptable

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
      let nxt = it.next
      yield it
      it = nxt
      if it == L.head: break

template findImpl() {.dirty.} =
  for x in nodes(L):
    if x.value == value: return x

iterator items*[T](L: SinglyLinkedList[T]): T =
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: DoublyLinkedList[T]): T =
  ## yields every value of `L`.
  itemsListImpl()

iterator items*[T](L: SinglyLinkedRing[T]): T =
  ## yields every value of `L`.
  itemsRingImpl()

iterator items*[T](L: DoublyLinkedRing[T]): T =
  ## yields every value of `L`.
  itemsRingImpl()

iterator mitems*[T](L: var SinglyLinkedList[T]): var T =
  ## yields every value of `L` so that you can modify it.
  itemsListImpl()

iterator mitems*[T](L: var DoublyLinkedList[T]): var T =
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

iterator findAll*[T](L: SinglyLinkedList[T] | SinglyLinkedRing[T], value: T): SinglyLinkedNode[T] =
  ## Iterates over the list `L` and returns all nodes matching `value`.
  for n in nodes(L):
    if n.value == value: yield(n)

iterator findAll*[T](L: DoublyLinkedList[T] | DoublyLinkedRing[T], value: T): DoublyLinkedNode[T] =
  ## Iterates over the list `L` and returns all nodes matching `value`.
  for n in nodes(L):
    if n.value == value: yield(n)

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
  ## prepends a node `n` to `L`. Efficiency: O(1).
  n.next = L.head
  L.head = n
  if L.tail == nil: L.tail = n

proc append*[T](L: var SinglyLinkedList[T],
                 n: SinglyLinkedNode[T]) {.inline.} =
  ## appends a node 'n' to `L`. Efficiency: O(1).
  n.next = nil
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## prepends a value to `L`. Efficiency: O(1).
  prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## prepends a value to `L`. Efficiency: O(1).
  append(L, newSinglyLinkedNode(value))

proc remove*[T](L: var SinglyLinkedList[T], n: SinglyLinkedNode[T]) =
  ## removes `n` from `L`. Efficiency: O(n).
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
  ## removes first `value` from `L`. Efficiency: O(n).
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
  ## removes all `values` from `L`. Efficiency: O(n).
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

proc remove*[T](L: var DoublyLinkedList[T], value: T) =
  ## removes the first node matching `value` from `L`. Efficiency: O(n).
  L.remove(L.find(value))

proc removeAll*[T](L: var DoublyLinkedList[T], value: T) =
  ## removes all nodes matching `value` from `L`. Efficiency: O(n).
  for n in L.nodes:
    if n.value == value: L.remove(n)

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

proc remove*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## removes `n` from `L`. Efficiency: O(n).
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
  ## removes `n` from `L`. Efficiency: O(n).
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
  ## removes all nodes matching `value` from `L`. Efficiency: O(n).
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
      L.head = L.head.next

proc remove*[T](L: var DoublyLinkedRing[T], value: T) =
  ## removes the first node matching `value` from `L`. Efficiency: O(1).
  L.remove(L.find(value))

proc removeAll*[T](L: var DoublyLinkedRing[T], value: T) =
  ## removes the first node matching `value` from `L`. Efficiency: O(n).

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

proc `==`[T](a, b: SinglyLinkedList[T] | SinglyLinkedRing[T]): bool {.inline.} =
  var p: SinglyLinkedNode[T] = b.head
  for v in a.items:
    if p.value != v: return
    p = p.next
  result = true

proc `==`[T](a, b: DoublyLinkedList[T] | DoublyLinkedRing[T]): bool {.inline.} =
  var p: DoublyLinkedNode[T] = b.head
  for v in a.items:
    if p.value != v: return
    p = p.next
  result = true

proc toSeq*[T](sll: SinglyLinkedList[T]): seq[T] =
  result = @[]
  for v in sll.items:
    result.add(v)

proc toSeq*[T](dll: DoublyLinkedList[T]): seq[T] =
  result = @[]
  for v in dll.items:
    result.add(v)

proc toSeq*[T](slr: SinglyLinkedRing[T]): seq[T] =
  result = @[]
  for v in slr.items:
    result.add(v)

proc toSeq*[T](dlr: DoublyLinkedRing[T]): seq[T] =
  result = @[]
  for v in dlr.items:
    result.add(v)

proc toSinglyLinkedList*[T](s: seq[T]): SinglyLinkedList[T] =
  ## Return a SinglyLinkedList containing a copy of the elements from `s`
  ##
  ## .. code-block:: nim
  ##   var a = @[1, 2, 3, 4].toSinglyLinkedList()
  result = initSinglyLinkedList[T]()
  for v in s:
    result.append(v)

proc toDoublyLinkedList*[T](s: openArray[T]): DoublyLinkedList[T] =
  ## Return a DoublyLinkedList containing a copy of the elements from `s`
  ##
  ## .. code-block:: nim
  ##   var a = @[1, 2, 3, 4].toDoublyLinkedList()
  result = initDoublyLinkedList[T]()
  for v in s:
    result.append(v)

proc toSinglyLinkedRing*[T](s: openArray[T]): SinglyLinkedRing[T] =
  ## Return a SinglyLinkedRing containing a copy of the elements from `s`
  ##
  ## .. code-block:: nim
  ##   var a = @[1, 2, 3, 4].toSinglyLinkedRing()
  result = initSinglyLinkedRing[T]()
  for v in s:
    result.append(v)

proc toDoublyLinkedRing*[T](s: openArray[T]): DoublyLinkedRing[T] =
  ## Return a DoublyLinkedRing containing a copy of the elements from `s`
  ##
  ## .. code-block:: nim
  ##   var a = @[1, 2, 3, 4].toDoublyLinkedRing()
  result = initDoublyLinkedRing[T]()
  for v in s:
    result.append(v)

proc map*[T, S](lst: SinglyLinkedList[T], op: proc (x: T): S {.closure.}): SinglyLinkedList[S] {.inline.} =
  ## Returns a new SinglyLinkedList with the results of `op` applied to every item in
  ## `lst`.
  ##
  ## Since the input is not modified you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence. Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toSinglyLinkedList()
  ##     b = map(a, proc(x: int): string = $x)
  ##   assert b == @["1", "2", "3", "4"].toSinglyLinkedList()
  result = initSinglyLinkedList[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: DoublyLinkedList[T], op: proc (x: T): S {.closure.}): DoublyLinkedList[S] {.inline.} =
  ## Returns a new DoublyLinkedList with the results of `op` applied to every item in
  ## `lst`.
  ##
  ## Since the input is not modified you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence. Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toDoublyLinkedList()
  ##     b = map(a, proc(x: int): string = $x)
  ##   assert b == @["1", "2", "3", "4"].toDoublyLinkedList()
  result = initDoublyLinkedList[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: SinglyLinkedRing[T], op: proc (x: T): S {.closure.}): SinglyLinkedRing[S] {.inline.} =
  ## Returns a new SinglyLinkedRing with the results of `op` applied to every item in
  ## `lst`.
  ##
  ## Since the input is not modified you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence. Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toSinglyLinkedRing()
  ##     b = map(a, proc(x: int): string = $x)
  ##   assert b == @["1", "2", "3", "4"].toSinglyLinkedRing()
  result = initSinglyLinkedRing[S]()
  for x in lst.items:
    result.append(op(x))

proc map*[T, S](lst: DoublyLinkedRing[T], op: proc (x: T): S {.closure.}): DoublyLinkedRing[S] {.inline.} =
  ## Returns a new DoublyLinkedRing with the results of `op` applied to every item in
  ## `lst`.
  ##
  ## Since the input is not modified you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence. Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toDoublyLinkedRing()
  ##     b = map(a, proc(x: int): string = $x)
  ##   assert b == @["1", "2", "3", "4"].toDoublyLinkedRing()
  result = initDoublyLinkedRing[S]()
  for x in lst.items():
    result.append(op(x))

proc apply*[T](lst: var SinglyLinkedList[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: op(v)

proc apply*[T](lst: var DoublyLinkedList[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: op(v)

proc apply*[T](lst: var SinglyLinkedRing[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: op(v)

proc apply*[T](lst: var DoublyLinkedRing[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: op(v)

proc apply*[T](lst: var SinglyLinkedList[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var DoublyLinkedList[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var SinglyLinkedRing[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: v = op(v)

proc apply*[T](lst: var DoublyLinkedRing[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `lst` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toSinglyLinkedList()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   # a --> ["142", "242", "342", "442"]
  ##
  for v in lst.mitems: v = op(v)


when isMainModule:
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

  block:  # toSeq()

    assert @[1,3,2,4].toSinglyLinkedList() == @[1,3,2,4].toSinglyLinkedList()
    assert sllm.toSeq() == @["1", "2", "3", "4"]
    assert sllm == toSinglyLinkedList(@["1", "2", "3", "4"])
    assert dllm.toSeq() == @["1", "2", "3", "4"]
    assert dllm == toDoublyLinkedList(@["1", "2", "3", "4"])
    assert slrm.toSeq() == @["1", "2", "3", "4"]
    assert slrm == toSinglyLinkedRing(@["1", "2", "3", "4"])
    assert dlrm.toSeq() == @["1", "2", "3", "4"]
    assert dlrm == toDoublyLinkedRing(@["1", "2", "3", "4"])

  block:  # apply( var T )

    sll.apply(proc(x: var int) = (x *= 2))
    assert sll == @[2,4,6,8].toSinglyLinkedList()
    sll.remove(4)
    assert sll == @[2,6,8].toSinglyLinkedList()
    sll.append(2)
    sll.removeAll(2)
    assert sll == @[6,8].toSinglyLinkedList()

    slr.apply(proc(x: var int) = (x *= 2))
    assert slr == @[2,4,6,8].toSinglyLinkedRing()
    slr.remove(4)
    assert slr == @[2,6,8].toSinglyLinkedRing()
    slr.append(2)
    slr.removeAll(2)
    assert slr == @[6,8].toSinglyLinkedRing()

    dll.apply(proc(x: var int) = (x *= 2))
    assert dll == @[2,4,6,8].toDoublyLinkedList()
    dll.remove(4)
    assert dll == @[2,6,8].toDoublyLinkedList()
    dll.append(2)
    dll.removeAll(2)
    assert dll == @[6,8].toDoublyLinkedList()

    dlr.apply(proc(x: var int) = (x *= 2))
    assert dlr == @[2,4,6,8].toDoublyLinkedRing()
    dlr.remove(4)
    assert dlr == @[2,6,8].toDoublyLinkedRing()
    dlr.append(2)
    dlr.removeAll(2)
    assert dlr == @[6,8].toDoublyLinkedRing()

  block:  # apply( T: T )

    sll.prepend(4); sll.prepend(2)
    sll.apply(proc(x: int): int = (1*x))
    assert sll == @[2,4,6,8].toSinglyLinkedList()
    sll.remove(4)
    assert sll == @[2,6,8].toSinglyLinkedList()
    sll.append(2)
    sll.removeAll(2)
    assert sll == @[6,8].toSinglyLinkedList()

    slr.prepend(4); slr.prepend(2)
    slr.apply(proc(x: int): int = (1*x))
    assert slr == @[2,4,6,8].toSinglyLinkedRing()
    slr.remove(4)
    assert slr == @[2,6,8].toSinglyLinkedRing()
    slr.append(2)
    slr.removeAll(2)
    assert slr == @[6,8].toSinglyLinkedRing()

    dll.prepend(4); dll.prepend(2)
    dll.apply(proc(x: int): int = (1*x))
    assert dll == @[2,4,6,8].toDoublyLinkedList()
    dll.remove(4)
    assert dll == @[2,6,8].toDoublyLinkedList()
    dll.append(2)
    dll.removeAll(2)
    assert dll == @[6,8].toDoublyLinkedList()

    dlr.prepend(4); dlr.prepend(2)
    dlr.apply(proc(x: int): int = (1*x))
    assert dlr == @[2,4,6,8].toDoublyLinkedRing()
    dlr.remove(4)
    assert dlr == @[2,6,8].toDoublyLinkedRing()
    dlr.append(2)
    dlr.removeAll(2)
    assert dlr == @[6,8].toDoublyLinkedRing()

  blocK:  # findAll()

    var c = 0
    sll.prepend(2); sll.prepend(4); sll.prepend(2)
    for n in sll.findAll(2): c += n.value
    assert c == 4

    c = 0
    dll.prepend(2); dll.prepend(4); dll.prepend(2)
    for n in dll.findAll(2): c += n.value
    assert c == 4

    c = 0
    slr.prepend(2); slr.prepend(4); slr.prepend(2)
    for n in slr.findAll(2): c += n.value
    assert c == 4

    c = 0
    dlr.prepend(2); dlr.prepend(4); dlr.prepend(2)
    for n in dlr.findAll(2): c += n.value
    assert c == 4
