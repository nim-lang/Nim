#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Identifier handling
# An identifier is a shared non-modifiable string that can be compared by its
# id. This module is essential for the compiler's performance.

import 
  hashes, strutils

type 
  TIdObj* = object of TObject
    id*: int # unique id; use this for comparisons and not the pointers
  
  PIdObj* = ref TIdObj
  PIdent* = ref TIdent
  TIdent*{.acyclic.} = object of TIdObj
    s*: string
    next*: PIdent             # for hash-table chaining
    h*: THash                 # hash value of s
  

proc getIdent*(identifier: string): PIdent
proc getIdent*(identifier: string, h: THash): PIdent
proc getIdent*(identifier: cstring, length: int, h: THash): PIdent
  # special version for the scanner; the scanner's buffering scheme makes
  # this horribly efficient. Most of the time no character copying is needed!
proc IdentEq*(id: PIdent, name: string): bool
# implementation

proc IdentEq(id: PIdent, name: string): bool = 
  result = id.id == getIdent(name).id

var buckets: array[0..4096 * 2 - 1, PIdent]

proc cmpIgnoreStyle(a, b: cstring, blen: int): int = 
  var 
    aa, bb: char
    i, j: int
  i = 0
  j = 0
  result = 1
  while j < blen: 
    while a[i] == '_': inc(i)
    while b[j] == '_': inc(j)
    # tolower inlined:
    aa = a[i]
    bb = b[j]
    if (aa >= 'A') and (aa <= 'Z'): aa = chr(ord(aa) + (ord('a') - ord('A')))
    if (bb >= 'A') and (bb <= 'Z'): bb = chr(ord(bb) + (ord('a') - ord('A')))
    result = ord(aa) - ord(bb)
    if (result != 0) or (aa == '\0'): break 
    inc(i)
    inc(j)
  if result == 0: 
    if a[i] != '\0': result = 1
  
proc cmpExact(a, b: cstring, blen: int): int = 
  var 
    aa, bb: char
    i, j: int
  i = 0
  j = 0
  result = 1
  while j < blen: 
    aa = a[i]
    bb = b[j]
    result = ord(aa) - ord(bb)
    if (result != 0) or (aa == '\0'): break 
    inc(i)
    inc(j)
  if result == 0: 
    if a[i] != '\0': result = 1
  
proc getIdent(identifier: string): PIdent = 
  result = getIdent(cstring(identifier), len(identifier), 
                    hashIgnoreStyle(identifier))

proc getIdent(identifier: string, h: THash): PIdent = 
  result = getIdent(cstring(identifier), len(identifier), h)

var wordCounter: int = 1

proc getIdent(identifier: cstring, length: int, h: THash): PIdent = 
  var 
    idx, id: int
    last: PIdent
  idx = h and high(buckets)
  result = buckets[idx]
  last = nil
  id = 0
  while result != nil: 
    if cmpExact(cstring(result.s), identifier, length) == 0: 
      if last != nil: 
        # make access to last looked up identifier faster:
        last.next = result.next
        result.next = buckets[idx]
        buckets[idx] = result
      return 
    elif cmpIgnoreStyle(cstring(result.s), identifier, length) == 0: 
      #if (id <> 0) and (id <> result.id) then begin
      #        result := buckets[idx];
      #        writeln('current id ', id);
      #        for i := 0 to len-1 do write(identifier[i]);
      #        writeln;
      #        while result <> nil do begin
      #          writeln(result.s, '  ', result.id);
      #          result := result.next
      #        end
      #      end;
      assert((id == 0) or (id == result.id))
      id = result.id
    last = result
    result = result.next
  new(result)
  result.h = h
  result.s = newString(length)
  for i in countup(0, length + 0 - 1): result.s[i] = identifier[i - 0]
  result.next = buckets[idx]
  buckets[idx] = result
  if id == 0: 
    inc(wordCounter)
    result.id = - wordCounter
  else: 
    result.id = id            #  writeln('new word ', result.s);
  
