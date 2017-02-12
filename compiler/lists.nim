#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module is deprecated, don't use it.
# TODO Remove this

import os

static:
  echo "WARNING: imported deprecated module compiler/lists.nim, use seq ore lists from the standard library"

type
  PListEntry* {.deprecated.} = ref TListEntry
  TListEntry* {.deprecated.} = object of RootObj
    prev*, next*: PListEntry

  TStrEntry* {.deprecated.} = object of TListEntry
    data*: string

  PStrEntry* {.deprecated.} = ref TStrEntry
  TLinkedList* {.deprecated.} = object       # for the "find" operation:
    head*, tail*: PListEntry
    counter*: int

  TCompareProc* {.deprecated.} = proc (entry: PListEntry, closure: pointer): bool {.nimcall.}

proc initLinkedList*(list: var TLinkedList) {.deprecated.} =
  list.counter = 0
  list.head = nil
  list.tail = nil

proc append*(list: var TLinkedList, entry: PListEntry) {.deprecated.} =
  inc(list.counter)
  entry.next = nil
  entry.prev = list.tail
  if list.tail != nil:
    assert(list.tail.next == nil)
    list.tail.next = entry
  list.tail = entry
  if list.head == nil: list.head = entry

proc contains*(list: TLinkedList, data: string): bool {.deprecated.} =
  var it = list.head
  while it != nil:
    if PStrEntry(it).data == data:
      return true
    it = it.next

proc newStrEntry(data: string): PStrEntry {.deprecated.} =
  new(result)
  result.data = data

proc appendStr*(list: var TLinkedList, data: string) {.deprecated.} =
  append(list, newStrEntry(data))

proc appendStr*(list: var seq[string]; data: string) {.deprecated.} =
  # just use system.add
  list.add(data)

proc includeStr*(list: var TLinkedList, data: string): bool {.deprecated.} =
  if contains(list, data): return true
  appendStr(list, data)       # else: add to list

proc includeStr(list: var seq[string]; data: string): bool {.deprecated.} =
  if list.contains(data):
    result = true
  else:
    result = false
    list.add data

proc prepend*(list: var TLinkedList, entry: PListEntry) {.deprecated.} =
  inc(list.counter)
  entry.prev = nil
  entry.next = list.head
  if list.head != nil:
    assert(list.head.prev == nil)
    list.head.prev = entry
  list.head = entry
  if list.tail == nil: list.tail = entry

proc prependStr*(list: var TLinkedList, data: string) {.deprecated.} =
  prepend(list, newStrEntry(data))

proc insertBefore*(list: var TLinkedList, pos, entry: PListEntry) {.deprecated.} =
  assert(pos != nil)
  if pos == list.head:
    prepend(list, entry)
  else:
    inc(list.counter)
    entry.next = pos
    entry.prev = pos.prev
    if pos.prev != nil: pos.prev.next = entry
    pos.prev = entry

proc remove*(list: var TLinkedList, entry: PListEntry) {.deprecated.} =
  dec(list.counter)
  if entry == list.tail:
    list.tail = entry.prev
  if entry == list.head:
    list.head = entry.next
  if entry.next != nil: entry.next.prev = entry.prev
  if entry.prev != nil: entry.prev.next = entry.next

proc bringToFront*(list: var TLinkedList, entry: PListEntry) {.deprecated.} =
  when true:
    list.remove entry
    list.prepend entry
  else:
    if entry == list.head: return
    if entry == list.tail: list.tail = entry.prev
    if entry.next != nil: entry.next.prev = entry.prev
    if entry.prev != nil: entry.prev.next = entry.next
    entry.prev = nil
    entry.next = list.head
    list.head = entry

proc excludePath*(list: var TLinkedList, data: string) {.deprecated.} =
  var it = list.head
  while it != nil:
    let nxt = it.next
    if cmpPaths(PStrEntry(it).data, data) == 0:
      remove(list, it)
    it = nxt

proc find*(list: TLinkedList, fn: TCompareProc, closure: pointer): PListEntry {.deprecated.} =
  result = list.head
  while result != nil:
    if fn(result, closure): return
    result = result.next
