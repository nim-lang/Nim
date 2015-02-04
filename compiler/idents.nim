#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Identifier handling
# An identifier is a shared immutable string that can be compared by its
# id. This module is essential for the compiler's performance.

import
  hashes, strutils

type
  TIdObj* = object of RootObj
    id*: int # unique id; use this for comparisons and not the pointers

  PIdObj* = ref TIdObj
  PIdent* = ref TIdent
  TIdent*{.acyclic.} = object of TIdObj
    s*: string
    next*: PIdent             # for hash-table chaining
    h*: THash                 # hash value of s

var firstCharIsCS*: bool = true
var buckets*: array[0..4096 * 2 - 1, PIdent]

proc cmpIgnoreStyle(a, b: cstring, blen: int): int =
  if firstCharIsCS:
    if a[0] != b[0]: return 1
  var i = 0
  var j = 0
  result = 1
  while j < blen:
    while a[i] == '_': inc(i)
    while b[j] == '_': inc(j)
    # tolower inlined:
    var aa = a[i]
    var bb = b[j]
    if aa >= 'A' and aa <= 'Z': aa = chr(ord(aa) + (ord('a') - ord('A')))
    if bb >= 'A' and bb <= 'Z': bb = chr(ord(bb) + (ord('a') - ord('A')))
    result = ord(aa) - ord(bb)
    if (result != 0) or (aa == '\0'): break
    inc(i)
    inc(j)
  if result == 0:
    if a[i] != '\0': result = 1

proc cmpExact(a, b: cstring, blen: int): int =
  var i = 0
  var j = 0
  result = 1
  while j < blen:
    var aa = a[i]
    var bb = b[j]
    result = ord(aa) - ord(bb)
    if (result != 0) or (aa == '\0'): break
    inc(i)
    inc(j)
  if result == 0:
    if a[i] != '\0': result = 1

var wordCounter = 1

proc getIdent*(identifier: cstring, length: int, h: THash): PIdent =
  var idx = h and high(buckets)
  result = buckets[idx]
  var last: PIdent = nil
  var id = 0
  while result != nil:
    if cmpExact(cstring(result.s), identifier, length) == 0:
      if last != nil:
        # make access to last looked up identifier faster:
        last.next = result.next
        result.next = buckets[idx]
        buckets[idx] = result
      return
    elif cmpIgnoreStyle(cstring(result.s), identifier, length) == 0:
      assert((id == 0) or (id == result.id))
      id = result.id
    last = result
    result = result.next
  new(result)
  result.h = h
  result.s = newString(length)
  for i in countup(0, length - 1): result.s[i] = identifier[i]
  result.next = buckets[idx]
  buckets[idx] = result
  if id == 0:
    inc(wordCounter)
    result.id = -wordCounter
  else:
    result.id = id

proc getIdent*(identifier: string): PIdent =
  result = getIdent(cstring(identifier), len(identifier),
                    hashIgnoreStyle(identifier))

proc getIdent*(identifier: string, h: THash): PIdent =
  result = getIdent(cstring(identifier), len(identifier), h)

proc identEq*(id: PIdent, name: string): bool =
  result = id.id == getIdent(name).id

var idAnon* = getIdent":anonymous"
let idDelegator* = getIdent":delegator"

