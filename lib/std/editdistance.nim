#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an algorithm to compute the
## `edit distance`:idx: between two Unicode strings.

import unicode

proc editDistance*(a, b: string): int {.noSideEffect.} =
  ## Returns the unicode-rune edit distance between ``a`` and ``b``.
  ##
  ## This uses the `Levenshtein`:idx: distance algorithm with only a linear
  ## memory overhead.
  if len(a) > len(b):
    # make ``b`` the longer string
    return editDistance(b, a)
  # strip common prefix
  var
    i_start = 0 ## The character starting index of the first rune in both strings ``a`` and ``b``
    i_next_a = 0
    i_next_b = 0
    rune_a, rune_b: Rune
    len_runes_a = 0 ## The number of relevant runes in string ``a``.
    len_runes_b = 0 ## The number of relevant runes in string ``b``.
  block commonPrefix:
    # ``a`` is the shorter string
    while i_start < len(a):
      i_next_a = i_start
      a.fastRuneAt(i_next_a, rune_a, doInc = true)
      i_next_b = i_start
      b.fastRuneAt(i_next_b, rune_b, doInc = true)
      if rune_a != rune_b:
        inc(len_runes_a)
        inc(len_runes_b)
        break
      i_start = i_next_a
  var
    # we know that we are either at the start of the strings
    # or that the current value of rune_a is not equal to rune_b
    # => start search for common suffix after the current rune (``i_next_*``)
    i_end_a = i_next_a ## The exclusive upper index bound of string ``a``.
    i_end_b = i_next_b ## The exclusive upper index bound of string ``b``.
    i_current_a = i_next_a
    i_current_b = i_next_b
  block commonSuffix:
    var
      add_runes_a = 0
      add_runes_b = 0
    while i_current_a < len(a) and i_current_b < len(b):
      i_next_a = i_current_a
      a.fastRuneAt(i_next_a, rune_a)
      i_next_b = i_current_b
      b.fastRuneAt(i_next_b, rune_b)
      inc(add_runes_a)
      inc(add_runes_b)
      if rune_a != rune_b:
        i_end_a = i_next_a
        i_end_b = i_next_b
        inc(len_runes_a, add_runes_a)
        inc(len_runes_b, add_runes_b)
        add_runes_a = 0
        add_runes_b = 0
      i_current_a = i_next_a
      i_current_b = i_next_b
    if i_current_a >= len(a): # ``a`` exhausted
      if i_current_b < len(b): # ``b`` not exhausted
        i_end_a = i_current_a
        i_end_b = i_current_b
        inc(len_runes_a, add_runes_a)
        inc(len_runes_b, add_runes_b)
        while true:
          b.fastRuneAt(i_end_b, rune_b)
          inc(len_runes_b)
          if i_end_b >= len(b): break
    elif i_current_b >= len(b): # ``b`` exhausted and ``a`` not exhausted
      i_end_a = i_current_a
      i_end_b = i_current_b
      inc(len_runes_a, add_runes_a)
      inc(len_runes_b, add_runes_b)
      while true:
        a.fastRuneAt(i_end_a, rune_a)
        inc(len_runes_a)
        if i_end_a >= len(a): break
  block specialCases:
    # trivial cases:
    if len_runes_a == 0: return len_runes_b
    if len_runes_b == 0: return len_runes_a
    # another special case:
    if len_runes_a == 1:
      a.fastRuneAt(i_start, rune_a, doInc = false)
      var i_current_b = i_start
      while i_current_b < i_end_b:
        b.fastRuneAt(i_current_b, rune_b, doInc = true)
        if rune_a == rune_b: return len_runes_b - 1
      return len_runes_b
  # common case:
  var
    len1 = len_runes_a + 1
    len2 = len_runes_b + 1
    row: seq[int]
  let half = len_runes_a div 2
  newSeq(row, len2)
  var e = i_start + len2 - 1 # end marker
  # initialize first row:
  for i in 1 .. (len2 - half - 1): row[i] = i
  row[0] = len1 - half - 1
  i_current_a = i_start
  var
    char2p_i = -1
    char2p_prev: int
  for i in 1 .. (len1 - 1):
    i_next_a = i_current_a
    a.fastRuneAt(i_next_a, rune_a)
    var
      char2p: int
      D, x: int
      p: int
    if i >= (len1 - half):
      # skip the upper triangle:
      let offset = i + half - len1
      if char2p_i == i:
        b.fastRuneAt(char2p_prev, rune_b)
        char2p = char2p_prev
        char2p_i = i + 1
      else:
        char2p = i_start
        for j in 0 ..< offset:
          rune_b = b.runeAt(char2p)
          inc(char2p, rune_b.size)
        char2p_i = i + 1
        char2p_prev = char2p
      p = offset
      rune_b = b.runeAt(char2p)
      var c3 = row[p] + (if rune_a != rune_b: 1 else: 0)
      inc(char2p, rune_b.size)
      inc(p)
      x = row[p] + 1
      D = x
      if x > c3: x = c3
      row[p] = x
      inc(p)
    else:
      p = 1
      char2p = i_start
      D = i
      x = i
    if i <= (half + 1):
      # skip the lower triangle:
      e = len2 + i - half - 2
    # main:
    while p <= e:
      dec(D)
      rune_b = b.runeAt(char2p)
      var c3 = D + (if rune_a != rune_b: 1 else: 0)
      inc(char2p, rune_b.size)
      inc(x)
      if x > c3: x = c3
      D = row[p] + 1
      if x > D: x = D
      row[p] = x
      inc(p)
    # lower triangle sentinel:
    if i <= half:
      dec(D)
      rune_b = b.runeAt(char2p)
      var c3 = D + (if rune_a != rune_b: 1 else: 0)
      inc(x)
      if x > c3: x = c3
      row[p] = x
    i_current_a = i_next_a
  result = row[e]

proc editDistanceAscii*(a, b: string): int {.noSideEffect.} =
  ## Returns the edit distance between `a` and `b`.
  ##
  ## This uses the `Levenshtein`:idx: distance algorithm with only a linear
  ## memory overhead.
  var len1 = a.len
  var len2 = b.len
  if len1 > len2:
    # make `b` the longer string
    return editDistanceAscii(b, a)

  # strip common prefix:
  var s = 0
  while s < len1 and a[s] == b[s]:
    inc(s)
    dec(len1)
    dec(len2)
  # strip common suffix:
  while len1 > 0 and len2 > 0 and a[s+len1-1] == b[s+len2-1]:
    dec(len1)
    dec(len2)
  # trivial cases:
  if len1 == 0: return len2
  if len2 == 0: return len1

  # another special case:
  if len1 == 1:
    for j in s..s+len2-1:
      if a[s] == b[j]: return len2 - 1
    return len2

  inc(len1)
  inc(len2)
  var half = len1 shr 1
  # initalize first row:
  #var row = cast[ptr array[0..high(int) div 8, int]](alloc(len2*sizeof(int)))
  var row: seq[int]
  newSeq(row, len2)
  var e = s + len2 - 1 # end marker
  for i in 1..len2 - half - 1: row[i] = i
  row[0] = len1 - half - 1
  for i in 1 .. len1 - 1:
    var char1 = a[i + s - 1]
    var char2p: int
    var D, x: int
    var p: int
    if i >= len1 - half:
      # skip the upper triangle:
      var offset = i - len1 + half
      char2p = offset
      p = offset
      var c3 = row[p] + ord(char1 != b[s + char2p])
      inc(p)
      inc(char2p)
      x = row[p] + 1
      D = x
      if x > c3: x = c3
      row[p] = x
      inc(p)
    else:
      p = 1
      char2p = 0
      D = i
      x = i
    if i <= half + 1:
      # skip the lower triangle:
      e = len2 + i - half - 2
    # main:
    while p <= e:
      dec(D)
      var c3 = D + ord(char1 != b[char2p + s])
      inc(char2p)
      inc(x)
      if x > c3: x = c3
      D = row[p] + 1
      if x > D: x = D
      row[p] = x
      inc(p)
    # lower triangle sentinel:
    if i <= half:
      dec(D)
      var c3 = D + ord(char1 != b[char2p + s])
      inc(x)
      if x > c3: x = c3
      row[p] = x
  result = row[e]


when isMainModule:
  doAssert editDistance("", "") == 0
  doAssert editDistance("kitten", "sitting") == 3 # from Wikipedia
  doAssert editDistance("flaw", "lawn") == 2 # from Wikipedia

  doAssert editDistance("привет", "превет") == 1
  doAssert editDistance("Åge", "Age") == 1
  # editDistance, one string is longer in bytes, but shorter in rune length
  # first string: 4 bytes, second: 6 bytes, but only 3 runes
  doAssert editDistance("aaaa", "×××") == 4

  block veryLongStringEditDistanceTest:
    const cap = 256
    var
      s1 = newStringOfCap(cap)
      s2 = newStringOfCap(cap)
    while len(s1) < cap:
      s1.add 'a'
    while len(s2) < cap:
      s2.add 'b'
    doAssert editDistance(s1, s2) == cap

  block combiningCodePointsEditDistanceTest:
    const s = "A\xCC\x8Age"
    doAssert editDistance(s, "Age") == 1

  doAssert editDistanceAscii("", "") == 0
  doAssert editDistanceAscii("kitten", "sitting") == 3 # from Wikipedia
  doAssert editDistanceAscii("flaw", "lawn") == 2 # from Wikipedia
