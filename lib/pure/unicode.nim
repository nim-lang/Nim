#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides support to handle the Unicode UTF-8 encoding.
##
## There are no specialized ``insert``, ``delete``, ``add`` and ``contains``
## procedures for ``seq[Rune]`` in this module because the generic variants
## of these procedures in the system module already work with it.
##
## The current version is compatible with Unicode v12.0.0.
##
##
## See also
## ========
## * `strutils module <strutils.html>`_
## * `unidecode module <unidecode.html>`_
## * `encodings module <encodings.html>`_

include "system/inclrtl"

type
  RuneImpl = range[0..0x10FFFF] # underlying type of Rune
  Rune* = distinct RuneImpl ## \
    ## Type that can hold a single Unicode code point.
    ##
    ## A Rune may be composed with other Runes to a character on the screen.
  Rune16* {.deprecated.} = distinct int16 ## \
    ## Type that can hold a single UTF-16 encoded character.
    ##
    ## A single Rune16 may not be enough to hold an arbitrary Unicode code point.

const InvalidChars = {'\xC0', '\xC1', '\xF5' .. '\xFF'} ## \
  ## These bytes can never occur in a valid UTF-8 sequence
const ReplacementRune* = Rune(0xFFFD) ## \
  ## The replacement rune (U+FFFD) is used as a replacement for invalid bytes
  ## in a UTF-8 string.

template ones(n: untyped): untyped = ((1 shl n)-1)

proc `<`*(a, b: Rune): bool {.borrow.}
proc `<=`*(a, b: Rune): bool {.borrow.}
proc `==`*(a, b: Rune): bool {.borrow.}

proc isOverlongEncoded(r: Rune, size: range[1..4]): bool =
  # See https://en.wikipedia.org/wiki/UTF-8#Description
  case size
  of 1:
    r < 0x0000.Rune or 0x007F.Rune < r
  of 2:
    r < 0x0080.Rune or 0x07FF.Rune < r
  of 3:
    r < 0x0800.Rune or 0xFFFF.Rune < r
  of 4:
    r < 0x10000.Rune or 0x10FFFF.Rune < r

proc isSurrogate(c: Rune): bool =
  0xD800.Rune <= c and c <= 0xDFFF.Rune

proc replaceSurrogate(r: Rune): Rune =
  if r.isSurrogate:
    ReplacementRune
  else:
    r

proc runeAndSizeAt*(s: string, i: Natural): tuple[rune: Rune, size: int] =
  ## Retrieve the rune starting at the byte inedx `i` as well as the
  ## number of bytes taken up by the rune.
  ##
  ## If there's no valid byte starting at `s[i]`,
  ## returns `(ReplacementRune, 1)`.
  if ord(s[i]) <=% 127:
    return (Rune(s[i]), 1)
  elif s[i] in InvalidChars or ord(s[i]) shr 6 == 0b10:
    return (ReplacementRune, 1)
  elif ord(s[i]) shr 5 == 0b110 and i <= s.len - 2 and
      ord(s[i+1]) shr 6 == 0b10:
    result = (Rune(
      (ord(s[i]) and (ones(5))) shl 6 or
      (ord(s[i+1]) and ones(6))), 2)
  elif ord(s[i]) shr 4 == 0b1110 and i <= s.len - 3 and
      ord(s[i+1]) shr 6 == 0b10 and
      ord(s[i+2]) shr 6 == 0b10:
    result = (Rune(
      (ord(s[i]) and ones(4)) shl 12 or
      (ord(s[i+1]) and ones(6)) shl 6 or
      (ord(s[i+2]) and ones(6))), 3)
  elif ord(s[i]) shr 3 == 0b11110 and i <= s.len - 4 and
      ord(s[i+1]) shr 6 == 0b10 and
      ord(s[i+2]) shr 6 == 0b10 and
      ord(s[i+3]) shr 6 == 0b10:
    result = (Rune(
      (ord(s[i]) and ones(3)) shl 18 or
      (ord(s[i+1]) and ones(6)) shl 12 or
      (ord(s[i+2]) and ones(6)) shl 6 or
      (ord(s[i+3]) and ones(6))), 4)
  else:
    return (ReplacementRune, 1)

  if isOverlongEncoded(result[0], result[1]):
    result = (ReplacementRune, 1)
  elif result[0].isSurrogate:
    result = (ReplacementRune, 1)

proc runeLen*(s: string): int {.rtl, extern: "nuc$1".} =
  ## Returns the number of runes of the string ``s``.
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeLen == 6
    ## note: a.len == 8

  var i = 0
  while i < len(s):
    i.inc runeAndSizeAt(s, i).size
    inc(result)

proc runeSizeAt*(s: string, i: Natural): int =
  ## Returns the number of bytes the rune starting at ``s[i]`` takes.
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeLenAt(0) == 1
    doAssert a.runeLenAt(1) == 2
  runeAndSizeAt(s, i).size

template fastRuneAt*(s: string, i: int, result: untyped, doInc = true)
    {.deprecated: "Use runeAndSizeAt instead".} =
  ## Returns the rune ``s[i]`` in ``result``.
  ##
  ## If ``doInc == true`` (default), ``i`` is incremented by the number
  ## of bytes that have been processed.
  let (rune, size) = runeAndSizeAt(s, i)
  when doInc:
    i.inc size
  result = rune

proc runeAt*(s: string, i: Natural): Rune =
  ## Returns the rune in ``s`` at **byte index** ``i``.
  ##
  ## See also:
  ## * `runeAtPos proc <#runeAtPos,string,int>`_
  ## * `runeStrAtPos proc <#runeStrAtPos,string,Natural>`_
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeAt(1) == "ñ".runeAt(0)
    ## a[2] is not the beginning of a Rune, so result is the replacement rune
    doAssert a.runeAt(2) == ReplacementRune
    doAssert a.runeAt(3) == "y".runeAt(0)
  runeAndSizeAt(s, i).rune

proc validateUtf8*(s: string): int =
  ## Returns the position of the invalid byte in ``s`` if the string ``s`` does
  ## not hold valid UTF-8 data. Otherwise ``-1`` is returned.
  ##
  ## See also:
  ## * `toUtf8 proc <#toUtf8,Rune>`_
  ## * `$ proc <#$,Rune>`_ alias for `toUtf8`
  ## * `add proc<#add,string,Rune>`_
  var i = 0
  while i < s.len:
    let (rune, size) = runeAndSizeAt(s, i)
    if rune == ReplacementRune and size == 1:
      return i
    i.inc size
  return -1

proc add*(s: var string; r: Rune) =
  ## Adds a rune ``c`` to a string ``s``.
  runnableExamples:
    var s = "abc"
    let c = "ä".runeAt(0)
    s.add(c)
    doAssert s == "abcä"
  let pos = s.len
  let i = replaceSurrogate(r).int
  if i <= 127:
    s.setLen(pos+1)
    s[pos+0] = chr(i)
  elif i <= 0x07FF:
    s.setLen(pos+2)
    s[pos+0] = chr((i shr 6) or 0b110_00000)
    s[pos+1] = chr((i and ones(6)) or 0b10_0000_00)
  elif i <= 0xFFFF:
    s.setLen(pos+3)
    s[pos+0] = chr(i shr 12 or 0b1110_0000)
    s[pos+1] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i and ones(6) or 0b10_0000_00)
  elif i <= 0x10FFFF:
    s.setLen(pos+4)
    s[pos+0] = chr(i shr 18 or 0b1111_0000)
    s[pos+1] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i and ones(6) or 0b10_0000_00)

proc toUtf8*(c: Rune): string {.rtl, extern: "nuc$1".} =
  ## Converts a rune into its UTF-8 representation.
  ##
  ## See also:
  ## * `validateUtf8 proc <#validateUtf8,string>`_
  ## * `$ proc <#$,Rune>`_ alias for `toUtf8`
  ## * `utf8 iterator <#utf8.i,string>`_
  ## * `add proc<#add,string,Rune>`_
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeAt(1).toUtf8 == "ñ"

  result.add c

proc `$`*(rune: Rune): string =
  ## An alias for `toUtf8 <#toUtf8,Rune>`_.
  ##
  ## See also:
  ## * `validateUtf8 proc <#validateUtf8,string>`_
  ## * `add proc<#add,string,Rune>`_
  rune.toUtf8

proc `$`*(runes: seq[Rune]): string =
  ## Converts a sequence of Runes to a string.
  ##
  ## See also:
  ## * `toRunes <#toRunes,string>`_ for a reverse operation
  runnableExamples:
    let
      someString = "öÑ"
      someRunes = toRunes(someString)
    doAssert $someRunes == someString

  result = ""
  for rune in runes:
    result.add rune

proc runeOffset*(s: string, pos: Natural, start: Natural = 0): int =
  ## Returns the byte position of rune
  ## at position ``pos`` in ``s`` with an optional start byte position.
  ## Returns the special value -1 if it runs out of the string.
  ##
  ## **Beware:** This can lead to unoptimized code and slow execution!
  ## Most problems can be solved more efficiently by using an iterator
  ## or conversion to a seq of Rune.
  ##
  ## See also:
  ## * `runeReverseOffset proc <#runeReverseOffset,string,Positive>`_
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeOffset(1) == 1
    doAssert a.runeOffset(3) == 4
    doAssert a.runeOffset(4) == 6

  var
    i = 0
    o = start
  while i < pos:
    o += runeSizeAt(s, o)
    if o >= s.len:
      return -1
    inc i
  return o

proc runeReverseOffset*(s: string, rev: Positive): (int, int) =
  ## Returns a tuple with the byte offset of the
  ## rune at position ``rev`` in ``s``, counting
  ## from the end (starting with 1) and the total
  ## number of runes in the string.
  ##
  ## Returns a negative value for offset if there are to few runes in
  ## the string to satisfy the request.
  ##
  ## **Beware:** This can lead to unoptimized code and slow execution!
  ## Most problems can be solved more efficiently by using an iterator
  ## or conversion to a seq of Rune.
  ##
  ## See also:
  ## * `runeOffset proc <#runeOffset,string,Natural,Natural>`_
  var
    a = rev.int
    o = 0
    x = 0
  while o < s.len:
    let r = runeSizeAt(s, o)
    o += r
    if a < 0:
      x += r
    dec a

  if a > 0:
    return (-a, rev.int-a)
  return (x, -a+rev.int)

proc runeAtPos*(s: string, pos: int): Rune =
  ## Returns the rune at position ``pos``.
  ##
  ## **Beware:** This can lead to unoptimized code and slow execution!
  ## Most problems can be solved more efficiently by using an iterator
  ## or conversion to a seq of Rune.
  ##
  ## See also:
  ## * `runeAt proc <#runeAt,string,Natural>`_
  ## * `runeStrAtPos proc <#runeStrAtPos,string,Natural>`_
  fastRuneAt(s, runeOffset(s, pos), result, false)

proc runeStrAtPos*(s: string, pos: Natural): string =
  ## Returns the rune at position ``pos`` as UTF8 String.
  ##
  ## **Beware:** This can lead to unoptimized code and slow execution!
  ## Most problems can be solved more efficiently by using an iterator
  ## or conversion to a seq of Rune.
  ##
  ## See also:
  ## * `runeAt proc <#runeAt,string,Natural>`_
  ## * `runeAtPos proc <#runeAtPos,string,int>`_
  let o = runeOffset(s, pos)
  s[o.. (o+runeSizeAt(s, o)-1)]

proc runeSubStr*(s: string, pos: int, len: int = int.high): string =
  ## Returns the UTF-8 substring starting at rune ``pos``
  ## with ``len`` runes.
  ##
  ## If ``pos`` or ``len`` is negative they count from
  ## the end of the string. If ``len`` is not given it means the longest
  ## possible string.
  runnableExamples:
    let s = "Hänsel  ««: 10,00€"
    doAssert(runeSubStr(s, 0, 2) == "Hä")
    doAssert(runeSubStr(s, 10, 1) == ":")
    doAssert(runeSubStr(s, -6) == "10,00€")
    doAssert(runeSubStr(s, 10) == ": 10,00€")
    doAssert(runeSubStr(s, 12, 5) == "10,00")
    doAssert(runeSubStr(s, -6, 3) == "10,")

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

include "includes/unicode_ranges"

proc binarySearch(c: RuneImpl, tab: openArray[int], len, stride: int): int =
  var n = len
  var t = 0
  while n > 1:
    var m = n div 2
    var p = t + m*stride
    if c >= tab[p]:
      t = p
      n = n-m
    else:
      n = m
  if n != 0 and c >= tab[t]:
    return t
  return -1

proc toLower*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into lower case. This works for any rune.
  ##
  ## If possible, prefer ``toLower`` over ``toUpper``.
  ##
  ## See also:
  ## * `toUpper proc <#toUpper,Rune>`_
  ## * `toTitle proc <#toTitle,Rune>`_
  ## * `isLower proc <#isLower,Rune>`_
  var c = RuneImpl(c)
  var p = binarySearch(c, toLowerRanges, len(toLowerRanges) div 3, 3)
  if p >= 0 and c >= toLowerRanges[p] and c <= toLowerRanges[p+1]:
    return Rune(c + toLowerRanges[p+2] - 500)
  p = binarySearch(c, toLowerSinglets, len(toLowerSinglets) div 2, 2)
  if p >= 0 and c == toLowerSinglets[p]:
    return Rune(c + toLowerSinglets[p+1] - 500)
  return Rune(c)

proc toUpper*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into upper case. This works for any rune.
  ##
  ## If possible, prefer ``toLower`` over ``toUpper``.
  ##
  ## See also:
  ## * `toLower proc <#toLower,Rune>`_
  ## * `toTitle proc <#toTitle,Rune>`_
  ## * `isUpper proc <#isUpper,Rune>`_
  var c = RuneImpl(c)
  var p = binarySearch(c, toUpperRanges, len(toUpperRanges) div 3, 3)
  if p >= 0 and c >= toUpperRanges[p] and c <= toUpperRanges[p+1]:
    return Rune(c + toUpperRanges[p+2] - 500)
  p = binarySearch(c, toUpperSinglets, len(toUpperSinglets) div 2, 2)
  if p >= 0 and c == toUpperSinglets[p]:
    return Rune(c + toUpperSinglets[p+1] - 500)
  return Rune(c)

proc toTitle*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` to title case.
  ##
  ## See also:
  ## * `toLower proc <#toLower,Rune>`_
  ## * `toUpper proc <#toUpper,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  var c = RuneImpl(c)
  var p = binarySearch(c, toTitleSinglets, len(toTitleSinglets) div 2, 2)
  if p >= 0 and c == toTitleSinglets[p]:
    return Rune(c + toTitleSinglets[p+1] - 500)
  return Rune(c)

proc isLower*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is a lower case rune.
  ##
  ## If possible, prefer ``isLower`` over ``isUpper``.
  ##
  ## See also:
  ## * `toLower proc <#toLower,Rune>`_
  ## * `isUpper proc <#isUpper,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  var c = RuneImpl(c)
  # Note: toUpperRanges is correct here!
  var p = binarySearch(c, toUpperRanges, len(toUpperRanges) div 3, 3)
  if p >= 0 and c >= toUpperRanges[p] and c <= toUpperRanges[p+1]:
    return true
  p = binarySearch(c, toUpperSinglets, len(toUpperSinglets) div 2, 2)
  if p >= 0 and c == toUpperSinglets[p]:
    return true

proc isUpper*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is a upper case rune.
  ##
  ## If possible, prefer ``isLower`` over ``isUpper``.
  ##
  ## See also:
  ## * `toUpper proc <#toUpper,Rune>`_
  ## * `isLower proc <#isLower,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  ## * `isAlpha proc <#isAlpha,Rune>`_
  ## * `isWhiteSpace proc <#isWhiteSpace,Rune>`_
  var c = RuneImpl(c)
  # Note: toLowerRanges is correct here!
  var p = binarySearch(c, toLowerRanges, len(toLowerRanges) div 3, 3)
  if p >= 0 and c >= toLowerRanges[p] and c <= toLowerRanges[p+1]:
    return true
  p = binarySearch(c, toLowerSinglets, len(toLowerSinglets) div 2, 2)
  if p >= 0 and c == toLowerSinglets[p]:
    return true

proc isAlpha*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is an *alpha* rune (i.e., a letter).
  ##
  ## See also:
  ## * `isLower proc <#isLower,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  ## * `isAlpha proc <#isAlpha,Rune>`_
  ## * `isWhiteSpace proc <#isWhiteSpace,Rune>`_
  ## * `isCombining proc <#isCombining,Rune>`_
  if isUpper(c) or isLower(c):
    return true
  var c = RuneImpl(c)
  var p = binarySearch(c, alphaRanges, len(alphaRanges) div 2, 2)
  if p >= 0 and c >= alphaRanges[p] and c <= alphaRanges[p+1]:
    return true
  p = binarySearch(c, alphaSinglets, len(alphaSinglets), 1)
  if p >= 0 and c == alphaSinglets[p]:
    return true

proc isTitle*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is a Unicode titlecase code point.
  ##
  ## See also:
  ## * `toTitle proc <#toTitle,Rune>`_
  ## * `isLower proc <#isLower,Rune>`_
  ## * `isUpper proc <#isUpper,Rune>`_
  ## * `isAlpha proc <#isAlpha,Rune>`_
  ## * `isWhiteSpace proc <#isWhiteSpace,Rune>`_
  return isUpper(c) and isLower(c)

proc isWhiteSpace*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is a Unicode whitespace code point.
  ##
  ## See also:
  ## * `isLower proc <#isLower,Rune>`_
  ## * `isUpper proc <#isUpper,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  ## * `isAlpha proc <#isAlpha,Rune>`_
  var c = RuneImpl(c)
  var p = binarySearch(c, spaceRanges, len(spaceRanges) div 2, 2)
  if p >= 0 and c >= spaceRanges[p] and c <= spaceRanges[p+1]:
    return true

proc isCombining*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true if ``c`` is a Unicode combining code unit.
  ##
  ## See also:
  ## * `isLower proc <#isLower,Rune>`_
  ## * `isUpper proc <#isUpper,Rune>`_
  ## * `isTitle proc <#isTitle,Rune>`_
  ## * `isAlpha proc <#isAlpha,Rune>`_
  var c = RuneImpl(c)

  # Optimized to return false immediately for ASCII
  return c >= 0x0300 and (c <= 0x036f or
    (c >= 0x1ab0 and c <= 0x1aff) or
    (c >= 0x1dc0 and c <= 0x1dff) or
    (c >= 0x20d0 and c <= 0x20ff) or
    (c >= 0xfe20 and c <= 0xfe2f))


template runeCheck(s, runeProc) =
  ## Common code for isAlpha and isSpace.
  result = if len(s) == 0: false else: true
  var
    i = 0
  while i < len(s) and result:
    let (rune, size) = runeAndSizeAt(s, i)
    i.inc size
    result = runeProc(rune) and result

proc isAlpha*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true if ``s`` contains all alphabetic runes.
  runnableExamples:
    let a = "añyóng"
    doAssert a.isAlpha
  runeCheck(s, isAlpha)

proc isSpace*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true if ``s`` contains all whitespace runes.
  runnableExamples:
    let a = "\t\l \v\r\f"
    doAssert a.isSpace
  runeCheck(s, isWhiteSpace)


template convertRune(s, runeProc) =
  ## Convert runes in ``s`` using ``runeProc`` as the converter.
  result = newStringOfCap(len(s))
  var i = 0
  while i < len(s):
    var (rune, size) = runeAndSizeAt(s, i)
    i.inc size
    rune = runeProc(rune)
    result.add rune

proc toUpper*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Converts ``s`` into upper-case runes.
  runnableExamples:
    doAssert toUpper("abγ") == "ABΓ"
  convertRune(s, toUpper)

proc toLower*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Converts ``s`` into lower-case runes.
  runnableExamples:
    doAssert toLower("ABΓ") == "abγ"
  convertRune(s, toLower)

proc swapCase*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1".} =
  ## Swaps the case of runes in ``s``.
  ##
  ## Returns a new string such that the cases of all runes
  ## are swapped if possible.
  runnableExamples:
    doAssert swapCase("Αlpha Βeta Γamma") == "αLPHA βETA γAMMA"

  var
    i = 0
    rune: Rune
  result = newStringOfCap(len(s))
  while i < len(s):
    fastRuneAt(s, i, rune)
    if rune.isUpper():
      rune = rune.toLower()
    elif rune.isLower():
      rune = rune.toUpper()
    result.add rune

proc capitalize*(s: string): string {.noSideEffect, procvar,
  rtl, extern: "nuc$1".} =
  ## Converts the first character of ``s`` into an upper-case rune.
  runnableExamples:
    doAssert capitalize("βeta") == "Βeta"

  if len(s) == 0:
    return s
  var
    rune: Rune
    i = 0
  fastRuneAt(s, i, rune, doInc=true)
  result = $toUpper(rune) & substr(s, i)

proc translate*(s: string, replacements: proc(key: string): string): string {.
  rtl, extern: "nuc$1".} =
  ## Translates words in a string using the ``replacements`` proc to substitute
  ## words inside ``s`` with their replacements.
  ##
  ## ``replacements`` is any proc that takes a word and returns
  ## a new word to fill it's place.
  runnableExamples:
    proc wordToNumber(s: string): string =
      case s
      of "one": "1"
      of "two": "2"
      else: s
    let a = "one two three four"
    doAssert a.translate(wordToNumber) == "1 2 three four"

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
  ## Converts ``s`` to a unicode title.
  ##
  ## Returns a new string such that the first character
  ## in each word inside ``s`` is capitalized.
  runnableExamples:
    doAssert title("αlpha βeta γamma") == "Αlpha Βeta Γamma"

  var
    i = 0
    rune: Rune
  result = newStringOfCap(len(s))
  var firstRune = true

  while i < len(s):
    fastRuneAt(s, i, rune)
    if not rune.isWhiteSpace() and firstRune:
      rune = rune.toUpper()
      firstRune = false
    elif rune.isWhiteSpace():
      firstRune = true
    result.add rune


iterator runes*(s: string): Rune =
  ## Iterates over any rune of the string ``s`` returning runes.
  var
    i = 0
    result: Rune
  while i < len(s):
    fastRuneAt(s, i, result, true)
    yield result

iterator utf8*(s: string): string =
  ## Iterates over any rune of the string ``s`` returning utf8 values.
  ##
  ## See also:
  ## * `validateUtf8 proc <#validateUtf8,string>`_
  ## * `toUtf8 proc <#toUtf8,Rune>`_
  ## * `$ proc <#$,Rune>`_ alias for `toUtf8`
  ## * `add proc<#add,string,Rune>`_
  var o = 0
  while o < s.len:
    let n = runeSizeAt(s, o)
    yield s[o.. (o+n-1)]
    o += n

proc toRunes*(s: string): seq[Rune] =
  ## Obtains a sequence containing the Runes in ``s``.
  ##
  ## See also:
  ## * `$ proc <#$,seq[T][Rune]>`_ for a reverse operation
  runnableExamples:
    let a = toRunes("aáä")
    doAssert a == @["a".runeAt(0), "á".runeAt(0), "ä".runeAt(0)]

  result = newSeq[Rune]()
  for r in s.runes:
    result.add(r)

proc cmpRunesIgnoreCase*(a, b: string): int {.rtl, extern: "nuc$1", procvar.} =
  ## Compares two UTF-8 strings and ignores the case. Returns:
  ##
  ## | 0 if a == b
  ## | < 0 if a < b
  ## | > 0 if a > b
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
  ## Returns the reverse of ``s``, interpreting it as runes.
  ##
  ## Unicode combining characters are correctly interpreted as well.
  runnableExamples:
    assert reversed("Reverse this!") == "!siht esreveR"
    assert reversed("先秦兩漢") == "漢兩秦先"
    assert reversed("as⃝df̅") == "f̅ds⃝a"
    assert reversed("a⃞b⃞c⃞") == "c⃞b⃞a⃞"

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
  ## The number of bytes belonging to byte index ``s[i]``,
  ## including following combining code unit.
  runnableExamples:
    let a = "añyóng"
    doAssert a.graphemeLen(1) == 2 ## ñ
    doAssert a.graphemeLen(2) == 1
    doAssert a.graphemeLen(4) == 2 ## ó

  var j = i.int
  var r, r2: Rune
  if j < s.len:
    fastRuneAt(s, j, r, true)
    result = j-i
    while j < s.len:
      fastRuneAt(s, j, r2, true)
      if not isCombining(r2): break
      result = j-i

proc lastRune*(s: string; last: Natural): tuple[rune: Rune, size: int] =
  ## Length of the last rune in ``s[0..last]``. Returns the rune and its size
  ## in bytes.
  var index = min(s.high, last)
  if s[index] <= chr(127):
    result = (Rune(s[last]), 1)
  else:
    while index >= 0 and uint(s[index]) shr 6 == 0b10: index.dec
    if index < 0:
      result = (ReplacementRune, 1)
    else:
      result = runeAndSizeAt(s, index)

proc size*(r: Rune): int {.noSideEffect.} =
  ## Returns the number of bytes the rune ``r`` takes
  ## when encoded as UTF-8.
  runnableExamples:
    let a = toRunes "aá"
    doAssert size(a[0]) == 1
    doAssert size(a[1]) == 2

  let v = replaceSurrogate(r).int
  if v <= 0x007F: result = 1
  elif v <= 0x07FF: result = 2
  elif v <= 0xFFFF: result = 3
  elif v <= 0x10FFFF: result = 4

proc stringHasSep(s: string, index: int, seps: openArray[Rune]): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return seps.contains(rune)

proc stringHasSep(s: string, index: int, sep: Rune): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return sep == rune

template splitCommon(s, sep, maxsplit: untyped, sepLen: int = -1) =
  ## Common code for split procedures.
  var
    last = 0
    splits = maxsplit
  if len(s) > 0:
    while last <= len(s):
      var first = last
      while last < len(s) and not stringHasSep(s, last, sep):
        when sep is Rune:
          inc(last, sepLen)
        else:
          inc(last, runeSizeAt(s, last))
      if splits == 0: last = len(s)
      yield s[first .. (last - 1)]
      if splits == 0: break
      dec(splits)
      when sep is Rune:
        inc(last, sepLen)
      else:
        inc(last, if last < len(s): runeSizeAt(s, last) else: 1)

iterator split*(s: string, seps: openArray[Rune] = unicodeSpaces,
  maxsplit: int = -1): string =
  ## Splits the unicode string ``s`` into substrings using a group of separators.
  ##
  ## Substrings are separated by a substring containing only ``seps``.
  ##
  ## .. code-block:: nim
  ##   for word in split("this\lis an\texample"):
  ##     writeLine(stdout, word)
  ##
  ## ...generates this output:
  ##
  ## .. code-block::
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  ## And the following code:
  ##
  ## .. code-block:: nim
  ##   for word in split("this:is;an$example", {';', ':', '$'}):
  ##     writeLine(stdout, word)
  ##
  ## ...produces the same output as the first example. The code:
  ##
  ## .. code-block:: nim
  ##   let date = "2012-11-20T22:08:08.398990"
  ##   let separators = {' ', '-', ':', 'T'}
  ##   for number in split(date, separators):
  ##     writeLine(stdout, number)
  ##
  ## ...results in:
  ##
  ## .. code-block::
  ##   "2012"
  ##   "11"
  ##   "20"
  ##   "22"
  ##   "08"
  ##   "08.398990"
  ##
  splitCommon(s, seps, maxsplit)

iterator splitWhitespace*(s: string): string =
  ## Splits a unicode string at whitespace runes.
  splitCommon(s, unicodeSpaces, -1)

template accResult(iter: untyped) =
  result = @[]
  for x in iter: add(result, x)

proc splitWhitespace*(s: string): seq[string] {.noSideEffect,
  rtl, extern: "ncuSplitWhitespace".} =
  ## The same as the `splitWhitespace <#splitWhitespace.i,string>`_
  ## iterator, but is a proc that returns a sequence of substrings.
  accResult(splitWhitespace(s))

iterator split*(s: string, sep: Rune, maxsplit: int = -1): string =
  ## Splits the unicode string ``s`` into substrings using a single separator.
  ##
  ## Substrings are separated by the rune ``sep``.
  ## The code:
  ##
  ## .. code-block:: nim
  ##   for word in split(";;this;is;an;;example;;;", ';'):
  ##     writeLine(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block::
  ##   ""
  ##   ""
  ##   "this"
  ##   "is"
  ##   "an"
  ##   ""
  ##   "example"
  ##   ""
  ##   ""
  ##   ""
  ##
  splitCommon(s, sep, maxsplit, sep.size)

proc split*(s: string, seps: openArray[Rune] = unicodeSpaces, maxsplit: int = -1): seq[string] {.
  noSideEffect, rtl, extern: "nucSplitRunes".} =
  ## The same as the `split iterator <#split.i,string,openArray[Rune],int>`_,
  ## but is a proc that returns a sequence of substrings.
  accResult(split(s, seps, maxsplit))

proc split*(s: string, sep: Rune, maxsplit: int = -1): seq[string] {.noSideEffect,
  rtl, extern: "nucSplitRune".} =
  ## The same as the `split iterator <#split.i,string,Rune,int>`_, but is a proc
  ## that returns a sequence of substrings.
  accResult(split(s, sep, maxsplit))

proc strip*(s: string, leading = true, trailing = true,
            runes: openArray[Rune] = unicodeSpaces): string {.noSideEffect,
            rtl, extern: "nucStrip".} =
  ## Strips leading or trailing ``runes`` from ``s`` and returns
  ## the resulting string.
  ##
  ## If ``leading`` is true (default), leading ``runes`` are stripped.
  ## If ``trailing`` is true (default), trailing ``runes`` are stripped.
  ## If both are false, the string is returned unchanged.
  runnableExamples:
    let a = "\táñyóng   "
    doAssert a.strip == "áñyóng"
    doAssert a.strip(leading = false) == "\táñyóng"
    doAssert a.strip(trailing = false) == "áñyóng   "

  var
    sI = 0 ## starting index into string ``s``
    eI = len(s) - 1 ## ending index into ``s``, where the last ``Rune`` starts
  if leading:
    var
      i = 0
      xI: int ## value of ``sI`` at the beginning of the iteration
      rune: Rune
    while i < len(s):
      xI = i
      fastRuneAt(s, i, rune)
      sI = i # Assume to start from next rune
      if not runes.contains(rune):
        sI = xI # Go back to where the current rune starts
        break
  if trailing:
    var
      i = eI
      xI: int
      rune: Rune
    while i >= 0:
      xI = i
      fastRuneAt(s, xI, rune)
      var yI = i - 1
      while yI >= 0:
        var
          yIend = yI
          pRune: Rune
        fastRuneAt(s, yIend, pRune)
        if yIend < xI: break
        i = yI
        rune = pRune
        dec(yI)
      if not runes.contains(rune):
        eI = xI - 1
        break
      dec(i)
  let newLen = eI - sI + 1
  result = newStringOfCap(newLen)
  if newLen > 0:
    result.add s[sI .. eI]

proc repeat*(c: Rune, count: Natural): string {.noSideEffect,
  rtl, extern: "nucRepeatRune".} =
  ## Returns a string of ``count`` Runes ``c``.
  ##
  ## The returned string will have a rune-length of ``count``.
  runnableExamples:
    let a = "ñ".runeAt(0)
    doAssert a.repeat(5) == "ñññññ"

  let s = $c
  result = newStringOfCap(count * s.len)
  for i in 0 ..< count:
    result.add s

proc align*(s: string, count: Natural, padding = ' '.Rune): string {.
  noSideEffect, rtl, extern: "nucAlignString".} =
  ## Aligns a unicode string ``s`` with ``padding``, so that it has a rune-length
  ## of ``count``.
  ##
  ## ``padding`` characters (by default spaces) are added before ``s`` resulting in
  ## right alignment. If ``s.runelen >= count``, no spaces are added and ``s`` is
  ## returned unchanged. If you need to left align a string use the `alignLeft
  ## proc <#alignLeft,string,Natural>`_.
  runnableExamples:
    assert align("abc", 4) == " abc"
    assert align("a", 0) == "a"
    assert align("1232", 6) == "  1232"
    assert align("1232", 6, '#'.Rune) == "##1232"
    assert align("Åge", 5) == "  Åge"
    assert align("×", 4, '_'.Rune) == "___×"

  let sLen = s.runeLen
  if sLen < count:
    let padStr = $padding
    result = newStringOfCap(padStr.len * count)
    let spaces = count - sLen
    for i in 0 ..< spaces: result.add padStr
    result.add s
  else:
    result = s

proc alignLeft*(s: string, count: Natural, padding = ' '.Rune): string {.
    noSideEffect.} =
  ## Left-aligns a unicode string ``s`` with ``padding``, so that it has a
  ## rune-length of ``count``.
  ##
  ## ``padding`` characters (by default spaces) are added after ``s`` resulting in
  ## left alignment. If ``s.runelen >= count``, no spaces are added and ``s`` is
  ## returned unchanged. If you need to right align a string use the `align
  ## proc <#align,string,Natural>`_.
  runnableExamples:
    assert alignLeft("abc", 4) == "abc "
    assert alignLeft("a", 0) == "a"
    assert alignLeft("1232", 6) == "1232  "
    assert alignLeft("1232", 6, '#'.Rune) == "1232##"
    assert alignLeft("Åge", 5) == "Åge  "
    assert alignLeft("×", 4, '_'.Rune) == "×___"
  let sLen = s.runeLen
  if sLen < count:
    let padStr = $padding
    result = newStringOfCap(s.len + (count - sLen) * padStr.len)
    result.add s
    for i in sLen ..< count:
      result.add padStr
  else:
    result = s

# -----------------------------------------------------------------------------
# deprecated

template runeCaseCheck(s, runeProc, skipNonAlpha) =
  ## Common code for rune.isLower and rune.isUpper.
  if len(s) == 0: return false
  var
    i = 0
    hasAtleastOneAlphaRune = false
  while i < len(s):
    let (rune, size) = runeAndSizeAt(s, i)
    i.inc size
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

proc isLower*(s: string, skipNonAlpha: bool): bool {.
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".} =
  ## **Deprecated since version 0.20 since its semantics are unclear**
  ##
  ## Checks whether ``s`` is lower case.
  ##
  ## If ``skipNonAlpha`` is true, returns true if all alphabetical
  ## runes in ``s`` are lower case. Returns false if none of the
  ## runes in ``s`` are alphabetical.
  ##
  ## If ``skipNonAlpha`` is false, returns true only if all runes in
  ## ``s`` are alphabetical and lower case.
  ##
  ## For either value of ``skipNonAlpha``, returns false if ``s`` is
  ## an empty string.
  runeCaseCheck(s, isLower, skipNonAlpha)

proc isUpper*(s: string, skipNonAlpha: bool): bool {.
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".} =
  ## **Deprecated since version 0.20 since its semantics are unclear**
  ##
  ## Checks whether ``s`` is upper case.
  ##
  ## If ``skipNonAlpha`` is true, returns true if all alphabetical
  ## runes in ``s`` are upper case. Returns false if none of the
  ## runes in ``s`` are alphabetical.
  ##
  ## If ``skipNonAlpha`` is false, returns true only if all runes in
  ## ``s`` are alphabetical and upper case.
  ##
  ## For either value of ``skipNonAlpha``, returns false if ``s`` is
  ## an empty string.
  runeCaseCheck(s, isUpper, skipNonAlpha)

proc isTitle*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str",
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".}=
  ## **Deprecated since version 0.20 since its semantics are unclear**
  ##
  ## Checks whether or not ``s`` is a unicode title.
  ##
  ## Returns true if the first character in each word inside ``s``
  ## are upper case and there is at least one character in ``s``.
  if s.len == 0:
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

proc runeLenAt*(s: string, i: Natural): int
    {.deprecated: "Use runeSizeAt instead".} =
  ## Returns the number of bytes the rune starting at ``s[i]`` takes.
  runnableExamples:
    let a = "añyóng"
    doAssert a.runeLenAt(0) == 1
    doAssert a.runeLenAt(1) == 2
  runeSizeAt(s, i)

template fastToUtf8Copy*(c: Rune, s: var string, pos: int, doInc = true)
    {.deprecated: "use add instead".} =
  ## Copies UTF-8 representation of ``c`` into the preallocated string ``s``
  ## starting at position ``pos``.
  ##
  ## If ``doInc == true`` (default), ``pos`` is incremented
  ## by the number of bytes that have been processed.
  ##
  ## To be the most efficient, make sure ``s`` is preallocated
  ## with an additional amount equal to the byte length of ``c``.
  ##
  ## See also:
  ## * `validateUtf8 proc <#validateUtf8,string>`_
  ## * `toUtf8 proc <#toUtf8,Rune>`_
  ## * `$ proc <#$,Rune>`_ alias for `toUtf8`
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
  else:
    discard # error, exception?

when isMainModule:

  proc asRune(s: static[string]): Rune =
    ## Compile-time conversion proc for converting string literals to a Rune
    ## value. Returns the first Rune of the specified string.
    ##
    ## Shortcuts code like ``"å".runeAt(0)`` to ``"å".asRune`` and returns a
    ## compile-time constant.
    if s.len == 0: Rune(0)
    else: s.runeAt(0)

  let
    someString = "öÑ"
    someRunes = toRunes(someString)
    compared = (someString == $someRunes)
  doAssert compared == true

  proc testReplacements(word: string): string =
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

  doAssert translate("two not alpha foo βeta", testReplacements) == "2 12345 αlpha BAR beta"
  doAssert translate("  two not foo βeta  ", testReplacements) == "  2 12345 BAR beta  "

  doAssert title("foo bar") == "Foo Bar"
  doAssert title("αlpha βeta γamma") == "Αlpha Βeta Γamma"
  doAssert title("") == ""

  doAssert capitalize("βeta") == "Βeta"
  doAssert capitalize("foo") == "Foo"
  doAssert capitalize("") == ""

  doAssert swapCase("FooBar") == "fOObAR"
  doAssert swapCase(" ") == " "
  doAssert swapCase("Αlpha Βeta Γamma") == "αLPHA βETA γAMMA"
  doAssert swapCase("a✓B") == "A✓b"
  doAssert swapCase("Јамогујестистаклоитоминештети") == "јАМОГУЈЕСТИСТАКЛОИТОМИНЕШТЕТИ"
  doAssert swapCase("ὕαλονϕαγεῖνδύναμαιτοῦτοοὔμεβλάπτει") == "ὝΑΛΟΝΦΑΓΕῖΝΔΎΝΑΜΑΙΤΟῦΤΟΟὔΜΕΒΛΆΠΤΕΙ"
  doAssert swapCase("Կրնամապակիուտեևինծիանհանգիստչըներ") == "կՐՆԱՄԱՊԱԿԻՈՒՏԵևԻՆԾԻԱՆՀԱՆԳԻՍՏՉԸՆԵՐ"
  doAssert swapCase("") == ""

  doAssert isAlpha("r")
  doAssert isAlpha("α")
  doAssert isAlpha("ϙ")
  doAssert isAlpha("ஶ")
  doAssert(not isAlpha("$"))
  doAssert(not isAlpha(""))

  doAssert isAlpha("Βeta")
  doAssert isAlpha("Args")
  doAssert isAlpha("𐌼𐌰𐌲𐌲𐌻𐌴𐍃𐍄𐌰𐌽")
  doAssert isAlpha("ὕαλονϕαγεῖνδύναμαιτοῦτοοὔμεβλάπτει")
  doAssert isAlpha("Јамогујестистаклоитоминештети")
  doAssert isAlpha("Կրնամապակիուտեևինծիանհանգիստչըներ")
  doAssert(not isAlpha("$Foo✓"))
  doAssert(not isAlpha("⠙⠕⠑⠎⠝⠞"))

  doAssert isSpace("\t")
  doAssert isSpace("\l")
  doAssert(not isSpace("Β"))
  doAssert(not isSpace("Βeta"))

  doAssert isSpace("\t\l \v\r\f")
  doAssert isSpace("       ")
  doAssert(not isSpace(""))
  doAssert(not isSpace("ΑΓc   \td"))

  doAssert(not isLower(' '.Rune))

  doAssert(not isUpper(' '.Rune))

  doAssert toUpper("Γ") == "Γ"
  doAssert toUpper("b") == "B"
  doAssert toUpper("α") == "Α"
  doAssert toUpper("✓") == "✓"
  doAssert toUpper("ϙ") == "Ϙ"
  doAssert toUpper("") == ""

  doAssert toUpper("ΑΒΓ") == "ΑΒΓ"
  doAssert toUpper("AAccβ") == "AACCΒ"
  doAssert toUpper("A✓$β") == "A✓$Β"

  doAssert toLower("a") == "a"
  doAssert toLower("γ") == "γ"
  doAssert toLower("Γ") == "γ"
  doAssert toLower("4") == "4"
  doAssert toLower("Ϙ") == "ϙ"
  doAssert toLower("") == ""

  doAssert toLower("abcdγ") == "abcdγ"
  doAssert toLower("abCDΓ") == "abcdγ"
  doAssert toLower("33aaΓ") == "33aaγ"

  doAssert reversed("Reverse this!") == "!siht esreveR"
  doAssert reversed("先秦兩漢") == "漢兩秦先"
  doAssert reversed("as⃝df̅") == "f̅ds⃝a"
  doAssert reversed("a⃞b⃞c⃞") == "c⃞b⃞a⃞"
  doAssert reversed("ὕαλονϕαγεῖνδύναμαιτοῦτοοὔμεβλάπτει") == "ιετπάλβεμὔοοτῦοτιαμανύδνῖεγαϕνολαὕ"
  doAssert reversed("Јамогујестистаклоитоминештети") == "итетшенимотиолкатситсејугомаЈ"
  doAssert reversed("Կրնամապակիուտեևինծիանհանգիստչըներ") == "րենըչտսիգնահնաիծնիևետւոիկապամանրԿ"
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

  block splitTests:
    let s = " this is an example  "
    let s2 = ":this;is;an:example;;"
    let s3 = ":this×is×an:example××"
    doAssert s.split() == @["", "this", "is", "an", "example", "", ""]
    doAssert s2.split(seps = [':'.Rune, ';'.Rune]) == @["", "this", "is", "an", "example", "", ""]
    doAssert s3.split(seps = [':'.Rune, "×".asRune]) == @["", "this", "is", "an", "example", "", ""]
    doAssert s.split(maxsplit = 4) == @["", "this", "is", "an", "example  "]
    doAssert s.split(' '.Rune, maxsplit = 1) == @["", "this is an example  "]

  block stripTests:
    doAssert(strip("") == "")
    doAssert(strip(" ") == "")
    doAssert(strip("y") == "y")
    doAssert(strip("  foofoofoo  ") == "foofoofoo")
    doAssert(strip("sfoofoofoos", runes = ['s'.Rune]) == "foofoofoo")

    block:
      let stripTestRunes = ['b'.Rune, 'a'.Rune, 'r'.Rune]
      doAssert(strip("barfoofoofoobar", runes = stripTestRunes) == "foofoofoo")
    doAssert(strip("sfoofoofoos", leading = false, runes = ['s'.Rune]) == "sfoofoofoo")
    doAssert(strip("sfoofoofoos", trailing = false, runes = ['s'.Rune]) == "foofoofoos")

    block:
      let stripTestRunes = ["«".asRune, "»".asRune]
      doAssert(strip("«TEXT»", runes = stripTestRunes) == "TEXT")
    doAssert(strip("copyright©", leading = false, runes = ["©".asRune]) == "copyright")
    doAssert(strip("¿Question?", trailing = false, runes = ["¿".asRune]) == "Question?")
    doAssert(strip("×text×", leading = false, runes = ["×".asRune]) == "×text")
    doAssert(strip("×text×", trailing = false, runes = ["×".asRune]) == "text×")

  block repeatTests:
    doAssert repeat('c'.Rune, 5) == "ccccc"
    doAssert repeat("×".asRune, 5) == "×××××"

  block alignTests:
    doAssert align("abc", 4) == " abc"
    doAssert align("a", 0) == "a"
    doAssert align("1232", 6) == "  1232"
    doAssert align("1232", 6, '#'.Rune) == "##1232"
    doAssert align("1232", 6, "×".asRune) == "××1232"
    doAssert alignLeft("abc", 4) == "abc "
    doAssert alignLeft("a", 0) == "a"
    doAssert alignLeft("1232", 6) == "1232  "
    doAssert alignLeft("1232", 6, '#'.Rune) == "1232##"
    doAssert alignLeft("1232", 6, "×".asRune) == "1232××"

  block differentSizes:
    # upper and lower variants have different number of bytes
    doAssert toLower("AẞC") == "aßc"
    doAssert toLower("ȺẞCD") == "ⱥßcd"
    doAssert toUpper("ⱥbc") == "ȺBC"
    doAssert toUpper("rsⱦuv") == "RSȾUV"
    doAssert swapCase("ⱥbCd") == "ȺBcD"
    doAssert swapCase("XyꟆaB") == "xYᶎAb"
    doAssert swapCase("aᵹcᲈd") == "AꝽCꙊD"
