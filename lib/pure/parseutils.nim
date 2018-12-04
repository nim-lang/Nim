#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains helpers for parsing tokens, numbers, identifiers, etc.
##
## To unpack raw bytes look at the `streams <streams.html>`_ module.

{.deadCodeElim: on.}  # dce option deprecated

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

include "system/inclrtl"

const
  Whitespace = {' ', '\t', '\v', '\r', '\l', '\f'}
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  IdentStartChars = {'a'..'z', 'A'..'Z', '_'}
    ## copied from strutils

proc toLower(c: char): char {.inline.} =
  result = if c in {'A'..'Z'}: chr(ord(c)-ord('A')+ord('a')) else: c

proc parseHex*(s: string, number: var int, start = 0; maxLen = 0): int {.
  rtl, extern: "npuParseHex", noSideEffect.}  =
  ## Parses a hexadecimal number and stores its value in ``number``.
  ##
  ## Returns the number of the parsed characters or 0 in case of an error. This
  ## proc is sensitive to the already existing value of ``number`` and will
  ## likely not do what you want unless you make sure ``number`` is zero. You
  ## can use this feature to *chain* calls, though the result int will quickly
  ## overflow. Example:
  ##
  ## .. code-block:: nim
  ##   var value = 0
  ##   discard parseHex("0x38", value)
  ##   assert value == 56
  ##   discard parseHex("0x34", value)
  ##   assert value == 56 * 256 + 52
  ##   value = -1
  ##   discard parseHex("0x38", value)
  ##   assert value == -200
  ##
  ## If ``maxLen == 0`` the length of the hexadecimal number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'x', 'X'}): inc(i, 2)
  elif i < last and s[i] == '#': inc(i)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'9':
      number = number shl 4 or (ord(s[i]) - ord('0'))
      foundDigit = true
    of 'a'..'f':
      number = number shl 4 or (ord(s[i]) - ord('a') + 10)
      foundDigit = true
    of 'A'..'F':
      number = number shl 4 or (ord(s[i]) - ord('A') + 10)
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseOct*(s: string, number: var int, start = 0, maxLen = 0): int  {.
  rtl, extern: "npuParseOct", noSideEffect.} =
  ## Parses an octal number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  ##
  ## If ``maxLen == 0`` the length of the octal number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'o', 'O'}): inc(i, 2)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'7':
      number = number shl 3 or (ord(s[i]) - ord('0'))
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseBin*(s: string, number: var int, start = 0, maxLen = 0): int  {.
  rtl, extern: "npuParseBin", noSideEffect.} =
  ## Parses an binary number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  ##
  ## If ``maxLen == 0`` the length of the binary number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'b', 'B'}): inc(i, 2)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'1':
      number = number shl 1 or (ord(s[i]) - ord('0'))
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseIdent*(s: string, ident: var string, start = 0): int =
  ## parses an identifier and stores it in ``ident``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  var i = start
  if i < s.len and s[i] in IdentStartChars:
    inc(i)
    while i < s.len and s[i] in IdentChars: inc(i)
    ident = substr(s, start, i-1)
    result = i-start

proc parseIdent*(s: string, start = 0): string =
  ## parses an identifier and stores it in ``ident``.
  ## Returns the parsed identifier or an empty string in case of an error.
  result = ""
  var i = start
  if i < s.len and s[i] in IdentStartChars:
    inc(i)
    while i < s.len and s[i] in IdentChars: inc(i)
    result = substr(s, start, i-1)

proc parseToken*(s: string, token: var string, validChars: set[char],
                 start = 0): int {.inline, deprecated.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters in `validChars`.
  ##
  ## **Deprecated since version 0.8.12**: Use ``parseWhile`` instead.
  var i = start
  while i < s.len and s[i] in validChars: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc skipWhitespace*(s: string, start = 0): int {.inline.} =
  ## skips the whitespace starting at ``s[start]``. Returns the number of
  ## skipped characters.
  while start+result < s.len and s[start+result] in Whitespace: inc(result)

proc skip*(s, token: string, start = 0): int {.inline.} =
  ## skips the `token` starting at ``s[start]``. Returns the length of `token`
  ## or 0 if there was no `token` at ``s[start]``.
  while start+result < s.len and result < token.len and
      s[result+start] == token[result]:
    inc(result)
  if result != token.len: result = 0

proc skipIgnoreCase*(s, token: string, start = 0): int =
  ## same as `skip` but case is ignored for token matching.
  while start+result < s.len and result < token.len and
      toLower(s[result+start]) == toLower(token[result]): inc(result)
  if result != token.len: result = 0

proc skipUntil*(s: string, until: set[char], start = 0): int {.inline.} =
  ## Skips all characters until one char from the set `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  while start+result < s.len and s[result+start] notin until: inc(result)

proc skipUntil*(s: string, until: char, start = 0): int {.inline.} =
  ## Skips all characters until the char `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  while start+result < s.len and s[result+start] != until: inc(result)

proc skipWhile*(s: string, toSkip: set[char], start = 0): int {.inline.} =
  ## Skips all characters while one char from the set `token` is found.
  ## Returns number of characters skipped.
  while start+result < s.len and s[result+start] in toSkip: inc(result)

proc parseUntil*(s: string, token: var string, until: set[char],
                 start = 0): int {.inline.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters notin `until`.
  var i = start
  while i < s.len and s[i] notin until: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseUntil*(s: string, token: var string, until: char,
                 start = 0): int {.inline.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of any character that is not the `until` character.
  var i = start
  while i < s.len and s[i] != until: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseUntil*(s: string, token: var string, until: string,
                 start = 0): int {.inline.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of any character that comes before the `until`  token.
  if until.len == 0:
    token.setLen(0)
    return 0
  var i = start
  while i < s.len:
    if s[i] == until[0]:
      var u = 1
      while i+u < s.len and u < until.len and s[i+u] == until[u]:
        inc u
      if u >= until.len: break
    inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseWhile*(s: string, token: var string, validChars: set[char],
                 start = 0): int {.inline.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters in `validChars`.
  var i = start
  while i < s.len and s[i] in validChars: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc captureBetween*(s: string, first: char, second = '\0', start = 0): string =
  ## Finds the first occurrence of ``first``, then returns everything from there
  ## up to ``second`` (if ``second`` is '\0', then ``first`` is used).
  var i = skipUntil(s, first, start)+1+start
  result = ""
  discard s.parseUntil(result, if second == '\0': first else: second, i)

{.push overflowChecks: on.}
# this must be compiled with overflow checking turned on:
proc rawParseInt(s: string, b: var BiggestInt, start = 0): int =
  var
    sign: BiggestInt = -1
    i = start
  if i < s.len:
    if s[i] == '+': inc(i)
    elif s[i] == '-':
      inc(i)
      sign = 1
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      b = b * 10 - (ord(s[i]) - ord('0'))
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    b = b * sign
    result = i - start
{.pop.} # overflowChecks

proc parseBiggestInt*(s: string, number: var BiggestInt, start = 0): int {.
  rtl, extern: "npuParseBiggestInt", noSideEffect.} =
  ## parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `OverflowError` is raised if an overflow occurs.
  var res: BiggestInt
  # use 'res' for exception safety (don't write to 'number' in case of an
  # overflow exception):
  result = rawParseInt(s, res, start)
  number = res

proc parseInt*(s: string, number: var int, start = 0): int {.
  rtl, extern: "npuParseInt", noSideEffect.} =
  ## parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `OverflowError` is raised if an overflow occurs.
  var res: BiggestInt
  result = parseBiggestInt(s, res, start)
  if (sizeof(int) <= 4) and
      ((res < low(int)) or (res > high(int))):
    raise newException(OverflowError, "overflow")
  elif result != 0:
    number = int(res)

proc parseSaturatedNatural*(s: string, b: var int, start = 0): int =
  ## parses a natural number into ``b``. This cannot raise an overflow
  ## error. ``high(int)`` is returned for an overflow.
  ## The number of processed character is returned.
  ## This is usually what you really want to use instead of `parseInt`:idx:.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var res = 0
  ##   discard parseSaturatedNatural("848", res)
  ##   doAssert res == 848
  var i = start
  if i < s.len and s[i] == '+': inc(i)
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      let c = ord(s[i]) - ord('0')
      if b <= (high(int) - c) div 10:
        b = b * 10 + c
      else:
        b = high(int)
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    result = i - start

# overflowChecks doesn't work with BiggestUInt
proc rawParseUInt(s: string, b: var BiggestUInt, start = 0): int =
  var
    res = 0.BiggestUInt
    prev = 0.BiggestUInt
    i = start
  if i < s.len and s[i] == '+': inc(i) # Allow
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      prev = res
      res = res * 10 + (ord(s[i]) - ord('0')).BiggestUInt
      if prev > res:
        return 0 # overflowChecks emulation
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    b = res
    result = i - start

proc parseBiggestUInt*(s: string, number: var BiggestUInt, start = 0): int {.
  rtl, extern: "npuParseBiggestUInt", noSideEffect.} =
  ## parses an unsigned integer starting at `start` and stores the value
  ## into `number`.
  ## Result is the number of processed chars or 0 if there is no integer
  ## or overflow detected.
  var res: BiggestUInt
  # use 'res' for exception safety (don't write to 'number' in case of an
  # overflow exception):
  result = rawParseUInt(s, res, start)
  number = res

proc parseUInt*(s: string, number: var uint, start = 0): int {.
  rtl, extern: "npuParseUInt", noSideEffect.} =
  ## parses an unsigned integer starting at `start` and stores the value
  ## into `number`.
  ## Result is the number of processed chars or 0 if there is no integer or
  ## overflow detected.
  var res: BiggestUInt
  result = parseBiggestUInt(s, res, start)
  when sizeof(BiggestUInt) > sizeof(uint) and sizeof(uint) <= 4:
    if res > 0xFFFF_FFFF'u64:
      raise newException(OverflowError, "overflow")
  if result != 0:
    number = uint(res)

proc parseBiggestFloat*(s: string, number: var BiggestFloat, start = 0): int {.
  magic: "ParseBiggestFloat", importc: "nimParseBiggestFloat", noSideEffect.}
  ## parses a float starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if a parsing error
  ## occurred.

proc parseFloat*(s: string, number: var float, start = 0): int {.
  rtl, extern: "npuParseFloat", noSideEffect.} =
  ## parses a float starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there occurred a parsing
  ## error.
  var bf: BiggestFloat
  result = parseBiggestFloat(s, bf, start)
  if result != 0:
    number = bf

type
  InterpolatedKind* = enum   ## describes for `interpolatedFragments`
                             ## which part of the interpolated string is
                             ## yielded; for example in "str$$$var${expr}"
    ikStr,                   ## ``str`` part of the interpolated string
    ikDollar,                ## escaped ``$`` part of the interpolated string
    ikVar,                   ## ``var`` part of the interpolated string
    ikExpr                   ## ``expr`` part of the interpolated string

iterator interpolatedFragments*(s: string): tuple[kind: InterpolatedKind,
  value: string] =
  ## Tokenizes the string `s` into substrings for interpolation purposes.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   for k, v in interpolatedFragments("  $this is ${an  example}  $$"):
  ##     echo "(", k, ", \"", v, "\")"
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   (ikString, "  ")
  ##   (ikExpr, "this")
  ##   (ikString, " is ")
  ##   (ikExpr, "an  example")
  ##   (ikString, "  ")
  ##   (ikDollar, "$")
  var i = 0
  var kind: InterpolatedKind
  while true:
    var j = i
    if j < s.len and s[j] == '$':
      if j+1 < s.len and s[j+1] == '{':
        inc j, 2
        var nesting = 0
        block curlies:
          while j < s.len:
            case s[j]
            of '{': inc nesting
            of '}':
              if nesting == 0:
                inc j
                break curlies
              dec nesting
            else: discard
            inc j
          raise newException(ValueError,
            "Expected closing '}': " & substr(s, i, s.high))
        inc i, 2 # skip ${
        kind = ikExpr
      elif j+1 < s.len and s[j+1] in IdentStartChars:
        inc j, 2
        while j < s.len and s[j] in IdentChars: inc(j)
        inc i # skip $
        kind = ikVar
      elif j+1 < s.len and s[j+1] == '$':
        inc j, 2
        inc i # skip $
        kind = ikDollar
      else:
        raise newException(ValueError,
          "Unable to parse a varible name at " & substr(s, i, s.high))
    else:
      while j < s.len and s[j] != '$': inc j
      kind = ikStr
    if j > i:
      # do not copy the trailing } for ikExpr:
      yield (kind, substr(s, i, j-1-ord(kind == ikExpr)))
    else:
      break
    i = j

when isMainModule:
  import sequtils
  let input = "$test{}  $this is ${an{  example}}  "
  let expected = @[(ikVar, "test"), (ikStr, "{}  "), (ikVar, "this"),
                   (ikStr, " is "), (ikExpr, "an{  example}"), (ikStr, "  ")]
  doAssert toSeq(interpolatedFragments(input)) == expected

  var value = 0
  discard parseHex("0x38", value)
  doAssert value == 56
  discard parseHex("0x34", value)
  doAssert value == 56 * 256 + 52
  value = -1
  discard parseHex("0x38", value)
  doAssert value == -200

  value = -1
  doAssert(parseSaturatedNatural("848", value) == 3)
  doAssert value == 848

  value = -1
  discard parseSaturatedNatural("84899999999999999999324234243143142342135435342532453", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("9223372036854775808", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("9223372036854775807", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("18446744073709551616", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("18446744073709551615", value)
  doAssert value == high(int)

  value = -1
  doAssert(parseSaturatedNatural("1_000_000", value) == 9)
  doAssert value == 1_000_000

{.pop.}
