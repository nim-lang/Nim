#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides support to handle the Unicode UTF-8 encoding.

{.deadCodeElim: on.}  # dce option deprecated

include "system/inclrtl"
from algorithm import binarySearch
from sequtils import mapLiterals

type
  RuneImpl = int32 # underlying type of Rune
  Rune* = distinct RuneImpl   ## type that can hold any Unicode character
  Rune16* = distinct int16 ## 16 bit Unicode character

{.deprecated: [TRune: Rune, TRune16: Rune16].}

proc `<=%`*(a, b: Rune): bool {.borrow.}
proc `<%`*(a, b: Rune): bool = return int(a) <% int(b)
proc `==`*(a, b: Rune): bool {.borrow.}

proc `<`*(a, b: Rune): bool {.borrow.}
proc `<=`*(a, b: Rune): bool {.borrow.}

proc `<`*(a: Rune, b: RuneImpl): bool {.borrow.}
proc `<=`*(a: Rune, b: RuneImpl): bool {.borrow.}

proc `<`*(a: RuneImpl, b: Rune): bool {.borrow.}
proc `<=`*(a: RuneImpl, b: Rune): bool {.borrow.}

proc cmp*(a, b: Rune): int {.borrow.}
proc cmp*(a: Rune, b: RuneImpl): int {.borrow.}
proc cmp*(a: RuneImpl, b: Rune): int {.borrow.}

template ones(n: untyped): untyped = ((1 shl n)-1)

proc runeLen*(s: string): int {.rtl, extern: "nuc$1".} =
  ## Returns the number of Unicode characters of the string ``s``
  var i = 0
  while i < len(s):
    if ord(s[i]) <=% 127: inc(i)
    elif ord(s[i]) shr 5 == 0b110: inc(i, 2)
    elif ord(s[i]) shr 4 == 0b1110: inc(i, 3)
    elif ord(s[i]) shr 3 == 0b11110: inc(i, 4)
    elif ord(s[i]) shr 2 == 0b111110: inc(i, 5)
    elif ord(s[i]) shr 1 == 0b1111110: inc(i, 6)
    else: inc i
    inc(result)

proc runeLenAt*(s: string, i: Natural): int =
  ## Returns the number of bytes the rune starting at ``s[i]`` takes
  if ord(s[i]) <=% 127: result = 1
  elif ord(s[i]) shr 5 == 0b110: result = 2
  elif ord(s[i]) shr 4 == 0b1110: result = 3
  elif ord(s[i]) shr 3 == 0b11110: result = 4
  elif ord(s[i]) shr 2 == 0b111110: result = 5
  elif ord(s[i]) shr 1 == 0b1111110: result = 6
  else: result = 1

const replRune = Rune(0xFFFD)

template fastRuneAt*(s: string, i: int, result: untyped, doInc = true) =
  ## Returns the Unicode character ``s[i]`` in ``result``. If ``doInc == true``
  ## ``i`` is incremented by the number of bytes that have been processed.
  bind ones
  if ord(s[i]) <=% 127:
    result = Rune(ord(s[i]))
    when doInc: inc(i)
  elif ord(s[i]) shr 5 == 0b110:
    # assert(ord(s[i+1]) shr 6 == 0b10)
    if i <= s.len - 2:
      result = Rune((ord(s[i]) and (ones(5))) shl 6 or
                    (ord(s[i+1]) and ones(6)))
      when doInc: inc(i, 2)
    else:
      result = replRune
      when doInc: inc(i)
  elif ord(s[i]) shr 4 == 0b1110:
    # assert(ord(s[i+1]) shr 6 == 0b10)
    # assert(ord(s[i+2]) shr 6 == 0b10)
    if i <= s.len - 3:
      result = Rune((ord(s[i]) and ones(4)) shl 12 or
               (ord(s[i+1]) and ones(6)) shl 6 or
               (ord(s[i+2]) and ones(6)))
      when doInc: inc(i, 3)
    else:
      result = replRune
      when doInc: inc(i)
  elif ord(s[i]) shr 3 == 0b11110:
    # assert(ord(s[i+1]) shr 6 == 0b10)
    # assert(ord(s[i+2]) shr 6 == 0b10)
    # assert(ord(s[i+3]) shr 6 == 0b10)
    if i <= s.len - 4:
      result = Rune((ord(s[i]) and ones(3)) shl 18 or
               (ord(s[i+1]) and ones(6)) shl 12 or
               (ord(s[i+2]) and ones(6)) shl 6 or
               (ord(s[i+3]) and ones(6)))
      when doInc: inc(i, 4)
    else:
      result = replRune
      when doInc: inc(i)
  elif ord(s[i]) shr 2 == 0b111110:
    # assert(ord(s[i+1]) shr 6 == 0b10)
    # assert(ord(s[i+2]) shr 6 == 0b10)
    # assert(ord(s[i+3]) shr 6 == 0b10)
    # assert(ord(s[i+4]) shr 6 == 0b10)
    if i <= s.len - 5:
      result = Rune((ord(s[i]) and ones(2)) shl 24 or
               (ord(s[i+1]) and ones(6)) shl 18 or
               (ord(s[i+2]) and ones(6)) shl 12 or
               (ord(s[i+3]) and ones(6)) shl 6 or
               (ord(s[i+4]) and ones(6)))
      when doInc: inc(i, 5)
    else:
      result = replRune
      when doInc: inc(i)
  elif ord(s[i]) shr 1 == 0b1111110:
    # assert(ord(s[i+1]) shr 6 == 0b10)
    # assert(ord(s[i+2]) shr 6 == 0b10)
    # assert(ord(s[i+3]) shr 6 == 0b10)
    # assert(ord(s[i+4]) shr 6 == 0b10)
    # assert(ord(s[i+5]) shr 6 == 0b10)
    if i <= s.len - 6:
      result = Rune((ord(s[i]) and ones(1)) shl 30 or
               (ord(s[i+1]) and ones(6)) shl 24 or
               (ord(s[i+2]) and ones(6)) shl 18 or
               (ord(s[i+3]) and ones(6)) shl 12 or
               (ord(s[i+4]) and ones(6)) shl 6 or
               (ord(s[i+5]) and ones(6)))
      when doInc: inc(i, 6)
    else:
      result = replRune
      when doInc: inc(i)
  else:
    result = Rune(ord(s[i]))
    when doInc: inc(i)

proc validateUtf8*(s: string): int =
  ## Returns the position of the invalid byte in ``s`` if the string ``s`` does
  ## not hold valid UTF-8 data. Otherwise ``-1`` is returned.
  var i = 0
  let L = s.len
  while i < L:
    if ord(s[i]) <=% 127:
      inc(i)
    elif ord(s[i]) shr 5 == 0b110:
      if ord(s[i]) < 0xc2: return i # Catch overlong ascii representations.
      if i+1 < L and ord(s[i+1]) shr 6 == 0b10: inc(i, 2)
      else: return i
    elif ord(s[i]) shr 4 == 0b1110:
      if i+2 < L and ord(s[i+1]) shr 6 == 0b10 and ord(s[i+2]) shr 6 == 0b10:
        inc i, 3
      else: return i
    elif ord(s[i]) shr 3 == 0b11110:
      if i+3 < L and ord(s[i+1]) shr 6 == 0b10 and
                     ord(s[i+2]) shr 6 == 0b10 and
                     ord(s[i+3]) shr 6 == 0b10:
        inc i, 4
      else: return i
    else:
      return i
  return -1

proc runeAt*(s: string, i: Natural): Rune =
  ## Returns the unicode character in ``s`` at byte index ``i``
  fastRuneAt(s, i, result, false)

template fastToUTF8Copy*(c: Rune, s: var string, pos: int, doInc = true) =
  ## Copies UTF-8 representation of `c` into the preallocated string `s`
  ## starting at position `pos`. If `doInc == true`, `pos` is incremented
  ## by the number of bytes that have been processed.
  ##
  ## To be the most efficient, make sure `s` is preallocated
  ## with an additional amount equal to the byte length of
  ## `c`.
  var i = RuneImpl(c)
  if i <=% 127:
    s.setLen(pos+1)
    s[pos+0] = chr(i)
    when doInc: inc(pos)
  elif i <=% 0x07FF:
    s.setLen(pos+2)
    s[pos+0] = chr((i shr 6) or 0b110_00000)
    s[pos+1] = chr((i and ones(6)) or 0b10_0000_00)
    when doInc: inc(pos, 2)
  elif i <=% 0xFFFF:
    s.setLen(pos+3)
    s[pos+0] = chr(i shr 12 or 0b1110_0000)
    s[pos+1] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i and ones(6) or 0b10_0000_00)
    when doInc: inc(pos, 3)
  elif i <=% 0x001FFFFF:
    s.setLen(pos+4)
    s[pos+0] = chr(i shr 18 or 0b1111_0000)
    s[pos+1] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i and ones(6) or 0b10_0000_00)
    when doInc: inc(pos, 4)
  elif i <=% 0x03FFFFFF:
    s.setLen(pos+5)
    s[pos+0] = chr(i shr 24 or 0b111110_00)
    s[pos+1] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i and ones(6) or 0b10_0000_00)
    when doInc: inc(pos, 5)
  elif i <=% 0x7FFFFFFF:
    s.setLen(pos+6)
    s[pos+0] = chr(i shr 30 or 0b1111110_0)
    s[pos+1] = chr(i shr 24 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+5] = chr(i and ones(6) or 0b10_0000_00)
    when doInc: inc(pos, 6)
  else:
    discard # error, exception?

proc toUTF8*(c: Rune): string {.rtl, extern: "nuc$1".} =
  ## Converts a rune into its UTF-8 representation
  result = ""
  fastToUTF8Copy(c, result, 0, false)

proc `$`*(rune: Rune): string =
  ## Converts a Rune to a string
  rune.toUTF8

proc `$`*(runes: seq[Rune]): string =
  ## Converts a sequence of Runes to a string
  result = ""
  for rune in runes: result.add(rune.toUTF8)

proc runeOffset*(s: string, pos:Natural, start: Natural = 0): int =
  ## Returns the byte position of unicode character
  ## at position pos in s with an optional start byte position.
  ## returns the special value -1 if it runs out of the string
  ##
  ## Beware: This can lead to unoptimized code and slow execution!
  ## Most problems are solve more efficient by using an iterator
  ## or conversion to a seq of Rune.
  var
    i = 0
    o = start
  while i < pos:
    o += runeLenAt(s, o)
    if o >= s.len:
      return -1
    inc i
  return o

proc runeAtPos*(s: string, pos: int): Rune =
  ## Returns the unicode character at position pos
  ##
  ## Beware: This can lead to unoptimized code and slow execution!
  ## Most problems are solve more efficient by using an iterator
  ## or conversion to a seq of Rune.
  fastRuneAt(s, runeOffset(s, pos), result, false)

proc runeStrAtPos*(s: string, pos: Natural): string =
  ## Returns the unicode character at position pos as UTF8 String
  ##
  ## Beware: This can lead to unoptimized code and slow execution!
  ## Most problems are solve more efficient by using an iterator
  ## or conversion to a seq of Rune.
  let o = runeOffset(s, pos)
  s[o.. (o+runeLenAt(s, o)-1)]

proc runeReverseOffset*(s: string, rev:Positive): (int, int) =
  ## Returns a tuple with the the byte offset of the
  ## unicode character at position ``rev`` in s counting
  ## from the end (starting with 1) and the total
  ## number of runes in the string. Returns a negative value
  ## for offset if there are to few runes in the string to
  ## satisfy the request.
  ##
  ## Beware: This can lead to unoptimized code and slow execution!
  ## Most problems are solve more efficient by using an iterator
  ## or conversion to a seq of Rune.
  var
    a = rev.int
    o = 0
    x = 0
  while o < s.len:
    let r = runeLenAt(s, o)
    o += r
    if a < 0:
      x += r
    dec a

  if a > 0:
    return (-a, rev.int-a)
  return (x, -a+rev.int)

proc runeSubStr*(s: string, pos:int, len:int = int.high): string =
  ## Returns the UTF-8 substring starting at codepoint pos
  ## with len codepoints. If pos or len is negative they count from
  ## the end of the string. If len is not given it means the longest
  ## possible string.
  ##
  ## (Needs some examples)
  if pos < 0:
    let (o, rl) = runeReverseOffset(s, -pos)
    if len >= rl:
      result = s.substr(o, s.len-1)
    elif len < 0:
      let e = rl + len
      if e < 0:
        result = ""
      else:
        result = s.substr(o, runeOffset(s, e-(rl+pos) , o)-1)
    else:
      result = s.substr(o, runeOffset(s, len, o)-1)
  else:
    let o = runeOffset(s, pos)
    if o < 0:
      result = ""
    elif len == int.high:
      result = s.substr(o, s.len-1)
    elif len < 0:
      let (e, rl) = runeReverseOffset(s, -len)
      discard rl
      if e <= 0:
        result = ""
      else:
        result = s.substr(o, e-1)
    else:
      var e = runeOffset(s, len, o)
      if e < 0:
        e = s.len
      result = s.substr(o, e-1)

type
  RuneRange = tuple
    Lo, Hi: Rune

  CaseEntry = tuple
    From, To: Rune

proc cmpRune(r: RuneRange, c: Rune): int =
  if likely(c < r.Lo):
    return 1
  if likely(c > r.Hi):
    return -1
  return 0

proc cmpRune(e: CaseEntry, c: Rune): int =
  if likely(c < e.From):
    return 1
  if likely(c > e.From):
    return -1
  return 0

include "lib/pure/includes/ucdtables"

proc isAlpha*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is an *alpha* Unicode character (i.e., a letter)
  return binarySearch(Alphabetics, c, cmpRune) >= 0

proc isLower*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a lower case Unicode character.
  return binarySearch(LowerCases, c, cmpRune) >= 0

proc isUpper*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a upper case Unicode character.
  return binarySearch(UpperCases, c, cmpRune) >= 0

proc isTitle*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a Unicode titlecase character
  return isUpper(c) and isLower(c)

proc isWhiteSpace*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a Unicode whitespace character
  return binarySearch(WhiteSpaces, c, cmpRune) >= 0

proc isCombining*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a Unicode combining character
  var c = RuneImpl(c)

  # Optimized to return false immediately for ASCII
  return c >= 0x0300 and (c <= 0x036f or
    (c >= 0x1ab0 and c <= 0x1aff) or
    (c >= 0x1dc0 and c <= 0x1dff) or
    (c >= 0x20d0 and c <= 0x20ff) or
    (c >= 0xfe20 and c <= 0xfe2f))

proc toLower*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into lower case. This works for any Unicode character.
  let i = binarySearch(ToLowers, c, cmpRune)
  if likely(i >= 0):
    return ToLowers[i].To
  return c

proc toUpper*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into upper case. This works for any Unicode character.
  let i = binarySearch(ToUppers, c, cmpRune)
  if likely(i >= 0):
    return ToUppers[i].To
  return c

proc toTitle*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` to title case
  var i = binarySearch(TitleCases, c, cmpRune)
  if likely(i >= 0):
    i = binarySearch(CaseFoldings, c, cmpRune)
    if likely(i >= 0):
      return CaseFoldings[i].To
  return toUpper(c)

proc swapCase*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Swaps the case of ``c``
  let i = binarySearch(CaseFoldings, c, cmpRune)
  if likely(i >= 0):
    return CaseFoldings[i].To
  return c

template runeCheck(s, runeProc) =
  ## Common code for isAlpha and isSpace.
  result = if len(s) == 0: false else: true

  var
    i = 0
    rune: Rune

  while i < len(s) and result:
    fastRuneAt(s, i, rune, doInc=true)
    result = runeProc(rune) and result

proc isAlpha*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all alphabetic unicode characters.
  runeCheck(s, isAlpha)

proc isSpace*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all whitespace unicode characters.
  runeCheck(s, isWhiteSpace)

template runeCaseCheck(s, runeProc, skipNonAlpha) =
  ## Common code for rune.isLower and rune.isUpper.
  if len(s) == 0: return false

  var
    i = 0
    rune: Rune
    hasAtleastOneAlphaRune = false

  while i < len(s):
    fastRuneAt(s, i, rune, doInc=true)
    if skipNonAlpha:
      var runeIsAlpha = isAlpha(rune)
      if not hasAtleastOneAlphaRune:
        hasAtleastOneAlphaRune = runeIsAlpha
      if runeIsAlpha and (not runeProc(rune)):
        return false
    else:
      if not runeProc(rune):
        return false
  return if skipNonAlpha: hasAtleastOneAlphaRune else: true

proc isLower*(s: string, skipNonAlpha: bool): bool =
  ## Checks whether ``s`` is lower case.
  ##
  ## If ``skipNonAlpha`` is true, returns true if all alphabetical
  ## runes in ``s`` are lower case.  Returns false if none of the
  ## runes in ``s`` are alphabetical.
  ##
  ## If ``skipNonAlpha`` is false, returns true only if all runes in
  ## ``s`` are alphabetical and lower case.
  ##
  ## For either value of ``skipNonAlpha``, returns false if ``s`` is
  ## an empty string.
  runeCaseCheck(s, isLower, skipNonAlpha)

proc isUpper*(s: string, skipNonAlpha: bool): bool =
  ## Checks whether ``s`` is upper case.
  ##
  ## If ``skipNonAlpha`` is true, returns true if all alphabetical
  ## runes in ``s`` are upper case.  Returns false if none of the
  ## runes in ``s`` are alphabetical.
  ##
  ## If ``skipNonAlpha`` is false, returns true only if all runes in
  ## ``s`` are alphabetical and upper case.
  ##
  ## For either value of ``skipNonAlpha``, returns false if ``s`` is
  ## an empty string.
  runeCaseCheck(s, isUpper, skipNonAlpha)

template convertRune(s, runeProc) =
  ## Convert runes in `s` using `runeProc` as the converter.
  result = newString(len(s))

  var
    i = 0
    lastIndex = 0
    rune: Rune

  while i < len(s):
    lastIndex = i
    fastRuneAt(s, i, rune, doInc=true)
    rune = runeProc(rune)

    rune.fastToUTF8Copy(result, lastIndex)

proc toUpper*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Converts `s` into upper-case unicode characters.
  convertRune(s, toUpper)

proc toLower*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Converts `s` into lower-case unicode characters.
  convertRune(s, toLower)

proc swapCase*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Swaps the case of unicode characters in `s`
  ##
  ## Returns a new string such that the cases of all unicode characters
  ## are swapped if possible
  convertRune(s, swapCase)

proc capitalize*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1".} =
  ## Converts the first character of `s` into an upper-case unicode character.
  if len(s) == 0:
    return s

  var
    rune: Rune
    i = 0

  fastRuneAt(s, i, rune, doInc=true)

  result = $toUpper(rune) & substr(s, i)

proc translate*(s: string, replacements: proc(key: string): string): string {.
  rtl, extern: "nuc$1".} =
  ## Translates words in a string using the `replacements` proc to substitute
  ## words inside `s` with their replacements
  ##
  ## `replacements` is any proc that takes a word and returns
  ## a new word to fill it's place.

  # Allocate memory for the new string based on the old one.
  # If the new string length is less than the old, no allocations
  # will be needed. If the new string length is greater than the
  # old, then maybe only one allocation is needed
  result = newStringOfCap(s.len)

  var
    index = 0
    lastIndex = 0
    wordStart = 0
    inWord = false
    rune: Rune

  while index < len(s):
    lastIndex = index

    fastRuneAt(s, index, rune)

    let whiteSpace = rune.isWhiteSpace()

    if whiteSpace and inWord:
      # If we've reached the end of a word
      let word = s[wordStart ..< lastIndex]
      result.add(replacements(word))
      result.add($rune)

      inWord = false
    elif not whiteSpace and not inWord:
      # If we've hit a non space character and
      # are not currently in a word, track
      # the starting index of the word
      inWord = true
      wordStart = lastIndex
    elif whiteSpace:
      result.add($rune)

  if wordStart < len(s) and inWord:
    # Get the trailing word at the end
    let word = s[wordStart .. ^1]
    result.add(replacements(word))

proc title*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1".} =
  ## Converts `s` to a unicode title.
  ##
  ## Returns a new string such that the first character
  ## in each word inside `s` is capitalized

  var
    i = 0
    lastIndex = 0
    rune: Rune

  result = newString(len(s))

  var firstRune = true

  while i < len(s):
    lastIndex = i

    fastRuneAt(s, i, rune)

    if not rune.isWhiteSpace() and firstRune:
      rune = rune.toUpper()
      firstRune = false
    elif rune.isWhiteSpace():
      firstRune = true

    rune.fastToUTF8Copy(result, lastIndex)

proc isTitle*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".}=
  ## Checks whether or not `s` is a unicode title.
  ##
  ## Returns true if the first character in each word inside `s`
  ## are upper case and there is at least one character in `s`.
  if s.len() == 0:
    return false

  result = true

  var
    i = 0
    rune: Rune

  var firstRune = true

  while i < len(s) and result:
    fastRuneAt(s, i, rune, doInc=true)

    if not rune.isWhiteSpace() and firstRune:
      result = rune.isUpper() and result
      firstRune = false
    elif rune.isWhiteSpace():
      firstRune = true

iterator runes*(s: string): Rune =
  ## Iterates over any unicode character of the string ``s`` returning runes
  var
    i = 0
    result: Rune
  while i < len(s):
    fastRuneAt(s, i, result, true)
    yield result

iterator utf8*(s: string): string =
  ## Iterates over any unicode character of the string ``s`` returning utf8 values
  var o = 0
  while o < s.len:
    let n = runeLenAt(s, o)
    yield s[o.. (o+n-1)]
    o += n

proc toRunes*(s: string): seq[Rune] =
  ## Obtains a sequence containing the Runes in ``s``
  result = newSeq[Rune]()
  for r in s.runes:
    result.add(r)

proc cmpRunesIgnoreCase*(a, b: string): int {.rtl, extern: "nuc$1", procvar.} =
  ## Compares two UTF-8 strings and ignores the case. Returns:
  ##
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b
  var i = 0
  var j = 0
  var ar, br: Rune
  while i < a.len and j < b.len:
    # slow path:
    fastRuneAt(a, i, ar)
    fastRuneAt(b, j, br)
    result = RuneImpl(toLower(ar)) - RuneImpl(toLower(br))
    if result != 0: return
  result = a.len - b.len

proc reversed*(s: string): string =
  ## Returns the reverse of ``s``, interpreting it as Unicode characters.
  ## Unicode combining characters are correctly interpreted as well:
  ##
  ## .. code-block:: nim
  ##
  ##   assert reversed("Reverse this!") == "!siht esreveR"
  ##   assert reversed("先秦兩漢") == "漢兩秦先"
  ##   assert reversed("as⃝df̅") == "f̅ds⃝a"
  ##   assert reversed("a⃞b⃞c⃞") == "c⃞b⃞a⃞"
  var
    i = 0
    lastI = 0
    newPos = len(s) - 1
    blockPos = 0
    r: Rune

  template reverseUntil(pos) =
    var j = pos - 1
    while j > blockPos:
      result[newPos] = s[j]
      dec j
      dec newPos
    blockPos = pos - 1

  result = newString(len(s))

  while i < len(s):
    lastI = i
    fastRuneAt(s, i, r, true)
    if not isCombining(r):
      reverseUntil(lastI)

  reverseUntil(len(s))

proc graphemeLen*(s: string; i: Natural): Natural =
  ## The number of bytes belonging to 's[i]' including following combining
  ## characters.
  var j = i.int
  var r, r2: Rune
  if j < s.len:
    fastRuneAt(s, j, r, true)
    result = j-i
    while j < s.len:
      fastRuneAt(s, j, r2, true)
      if not isCombining(r2): break
      result = j-i

proc lastRune*(s: string; last: int): (Rune, int) =
  ## length of the last rune in 's[0..last]'. Returns the rune and its length
  ## in bytes.
  if s[last] <= chr(127):
    result = (Rune(s[last]), 1)
  else:
    var L = 0
    while last-L >= 0 and ord(s[last-L]) shr 6 == 0b10: inc(L)
    var r: Rune
    fastRuneAt(s, last-L, r, false)
    result = (r, L+1)

when isMainModule:
  let
    someString = "öÑ"
    someRunes = @[runeAt(someString, 0), runeAt(someString, 2)]
    compared = (someString == $someRunes)
  doAssert compared == true

  proc test_replacements(word: string): string =
    case word
    of "two":
      return "2"
    of "foo":
      return "BAR"
    of "βeta":
      return "beta"
    of "alpha":
      return "αlpha"
    else:
      return "12345"

  doAssert translate("two not alpha foo βeta", test_replacements) == "2 12345 αlpha BAR beta"
  doAssert translate("  two not foo βeta  ", test_replacements) == "  2 12345 BAR beta  "

  doAssert title("foo bar") == "Foo Bar"
  doAssert title("αlpha βeta γamma") == "Αlpha Βeta Γamma"
  doAssert title("") == ""

  doAssert capitalize("βeta") == "Βeta"
  doAssert capitalize("foo") == "Foo"
  doAssert capitalize("") == ""

  doAssert isTitle("Foo")
  doAssert(not isTitle("Foo bar"))
  doAssert(not isTitle("αlpha Βeta"))
  doAssert(isTitle("Αlpha Βeta Γamma"))
  doAssert(not isTitle("fFoo"))

  doAssert swapCase("FooBar") == "fOObAR"
  doAssert swapCase(" ") == " "
  doAssert swapCase("Αlpha Βeta Γamma") == "αLPHA βETA γAMMA"
  doAssert swapCase("a✓B") == "A✓b"
  doAssert swapCase("") == ""

  doAssert isAlpha("r")
  doAssert isAlpha("α")
  doAssert(not isAlpha("$"))
  doAssert(not isAlpha(""))

  doAssert isAlpha("Βeta")
  doAssert isAlpha("Args")
  doAssert(not isAlpha("$Foo✓"))

  doAssert isSpace("\t")
  doAssert isSpace("\l")
  doAssert(not isSpace("Β"))
  doAssert(not isSpace("Βeta"))

  doAssert isSpace("\t\l \v\r\f")
  doAssert isSpace("       ")
  doAssert(not isSpace(""))
  doAssert(not isSpace("ΑΓc   \td"))

  doAssert(not isLower(' '.Rune))

  doAssert isLower("a", false)
  doAssert isLower("γ", true)
  doAssert(not isLower("Γ", false))
  doAssert(not isLower("4", true))
  doAssert(not isLower("", false))
  doAssert isLower("abcdγ", false)
  doAssert(not isLower("33aaΓ", false))
  doAssert(not isLower("a b", false))

  doAssert(not isLower("abCDΓ", true))
  doAssert isLower("a b", true)
  doAssert isLower("1, 2, 3 go!", true)
  doAssert(not isLower(" ", true))
  doAssert(not isLower("(*&#@(^#$✓ ", true)) # None of the string runes are alphabets

  doAssert(not isUpper(' '.Rune))

  doAssert isUpper("Γ", false)
  doAssert(not isUpper("α", false))
  doAssert(not isUpper("", false))
  doAssert isUpper("ΑΒΓ", false)
  doAssert(not isUpper("A#$β", false))
  doAssert(not isUpper("A B", false))

  doAssert(not isUpper("b", true))
  doAssert(not isUpper("✓", true))
  doAssert(not isUpper("AAccβ", true))
  doAssert isUpper("A B", true)
  doAssert isUpper("1, 2, 3 GO!", true)
  doAssert(not isUpper(" ", true))
  doAssert(not isUpper("(*&#@(^#$✓ ", true)) # None of the string runes are alphabets

  doAssert toUpper("Γ") == "Γ"
  doAssert toUpper("b") == "B"
  doAssert toUpper("α") == "Α"
  doAssert toUpper("✓") == "✓"
  doAssert toUpper("") == ""

  doAssert toUpper("ΑΒΓ") == "ΑΒΓ"
  doAssert toUpper("AAccβ") == "AACCΒ"
  doAssert toUpper("A✓$β") == "A✓$Β"

  doAssert toLower("a") == "a"
  doAssert toLower("γ") == "γ"
  doAssert toLower("Γ") == "γ"
  doAssert toLower("4") == "4"
  doAssert toLower("") == ""

  doAssert toLower("abcdγ") == "abcdγ"
  doAssert toLower("abCDΓ") == "abcdγ"
  doAssert toLower("33aaΓ") == "33aaγ"

  doAssert reversed("Reverse this!") == "!siht esreveR"
  doAssert reversed("先秦兩漢") == "漢兩秦先"
  doAssert reversed("as⃝df̅") == "f̅ds⃝a"
  doAssert reversed("a⃞b⃞c⃞") == "c⃞b⃞a⃞"
  doAssert len(toRunes("as⃝df̅")) == runeLen("as⃝df̅")
  const test = "as⃝"
  doAssert lastRune(test, test.len-1)[1] == 3
  doAssert graphemeLen("è", 0) == 2

  # test for rune positioning and runeSubStr()
  let s = "Hänsel  ««: 10,00€"

  var t = ""
  for c in s.utf8:
    t.add c

  doAssert(s == t)

  doAssert(runeReverseOffset(s, 1) == (20, 18))
  doAssert(runeReverseOffset(s, 19) == (-1, 18))

  doAssert(runeStrAtPos(s, 0) == "H")
  doAssert(runeSubStr(s, 0, 1) == "H")
  doAssert(runeStrAtPos(s, 10) == ":")
  doAssert(runeSubStr(s, 10, 1) == ":")
  doAssert(runeStrAtPos(s, 9) == "«")
  doAssert(runeSubStr(s, 9, 1) == "«")
  doAssert(runeStrAtPos(s, 17) == "€")
  doAssert(runeSubStr(s, 17, 1) == "€")
  # echo runeStrAtPos(s, 18) # index error

  doAssert(runeSubStr(s, 0) == "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, -18) == "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, 10) == ": 10,00€")
  doAssert(runeSubStr(s, 18) == "")
  doAssert(runeSubStr(s, 0, 10) == "Hänsel  ««")

  doAssert(runeSubStr(s, 12) == "10,00€")
  doAssert(runeSubStr(s, -6) == "10,00€")

  doAssert(runeSubStr(s, 12, 5) == "10,00")
  doAssert(runeSubStr(s, 12, -1) == "10,00")
  doAssert(runeSubStr(s, -6, 5) == "10,00")
  doAssert(runeSubStr(s, -6, -1) == "10,00")

  doAssert(runeSubStr(s, 0, 100) == "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, -100, 100) == "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, 0, -100) == "")
  doAssert(runeSubStr(s, 100, -100) == "")