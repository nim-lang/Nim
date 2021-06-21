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
  hashes, wordrecg

type
  PIdent* = ref TIdent
  TIdent*{.acyclic.} = object
    id*: int # unique id; use this for comparisons and not the pointers
    s*: string
    next*: PIdent             # for hash-table chaining
    h*: Hash                 # hash value of s

  IdentCache* = ref object
    buckets: array[0..4096 * 2 - 1, PIdent]
    wordCounter: int
    idAnon*, idDelegator*, emptyIdent*: PIdent

proc resetIdentCache*() = discard

proc cmpIgnoreStyle*(a, b: cstring, blen: int): int =
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

proc getIdent*(ic: IdentCache; identifier: cstring, length: int, h: Hash): PIdent =
  var idx = h and high(ic.buckets)
  result = ic.buckets[idx]
  var last: PIdent = nil
  var id = 0
  while result != nil:
    if cmpExact(cstring(result.s), identifier, length) == 0:
      if last != nil:
        # make access to last looked up identifier faster:
        last.next = result.next
        result.next = ic.buckets[idx]
        ic.buckets[idx] = result
      return
    elif cmpIgnoreStyle(cstring(result.s), identifier, length) == 0:
      assert((id == 0) or (id == result.id))
      id = result.id
    last = result
    result = result.next
  new(result)
  result.h = h
  result.s = newString(length)
  for i in 0..<length: result.s[i] = identifier[i]
  result.next = ic.buckets[idx]
  ic.buckets[idx] = result
  if id == 0:
    inc(ic.wordCounter)
    result.id = -ic.wordCounter
  else:
    result.id = id

proc getIdent*(ic: IdentCache; identifier: string): PIdent =
  result = getIdent(ic, cstring(identifier), identifier.len,
                    hashIgnoreStyle(identifier))

proc getIdent*(ic: IdentCache; identifier: string, h: Hash): PIdent =
  result = getIdent(ic, cstring(identifier), identifier.len, h)

proc newIdentCache*(): IdentCache =
  result = IdentCache()
  result.idAnon = result.getIdent":anonymous"
  result.wordCounter = 1
  result.idDelegator = result.getIdent":delegator"
  result.emptyIdent = result.getIdent("")
  # initialize the keywords:
  for s in succ(low(TSpecialWord))..high(TSpecialWord):
    result.getIdent($s, hashIgnoreStyle($s)).id = ord(s)

proc whichKeyword*(id: PIdent): TSpecialWord =
  if id.id < 0: result = wInvalid
  else: result = TSpecialWord(id.id)

proc hash*(x: PIdent): Hash {.inline.} = x.h
proc `==`*(a, b: PIdent): bool {.inline.} =
  if a.isNil or b.isNil: result = system.`==`(a, b)
  else: result = a.id == b.id
