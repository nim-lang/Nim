#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Template based implementation of singly and doubly linked lists.
## The involved types should have 'prev' or 'next' fields and the
## list header should have 'head' or 'tail' fields.

template prepend*(header, node) =
  when compiles(header.head):
    when compiles(node.prev):
      if header.head != nil:
        header.head.prev = node
    node.next = header.head
    header.head = node
  when compiles(header.tail):
    if header.tail == nil:
      header.tail = node

template append*(header, node) =
  when compiles(header.head):
    if header.head == nil:
      header.head = node
  when compiles(header.tail):
    when compiles(node.prev):
      node.prev = header.tail
    if header.tail != nil:
      header.tail.next = node
    header.tail = node

template unlink*(header, node) =
  if node.next != nil:
    node.next.prev = node.prev
  if node.prev != nil:
    node.prev.next = node.next
  if header.head == node:
    header.head = node.prev
  if header.tail == node:
    header.tail = node.next
