#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains helpers for parsing tokens, numbers, identifiers, etc.

{.deadCodeElim: on.}

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

proc parseHex*(s: string, number: var int, start = 0): int {.
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
  var i = start
  var foundDigit = false
  if s[i] == '0' and (s[i+1] == 'x' or s[i+1] == 'X'): inc(i, 2)
  elif s[i] == '#': inc(i)
  while true: 
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

proc parseOct*(s: string, number: var int, start = 0): int  {.
  rtl, extern: "npuParseOct", noSideEffect.} = 
  ## parses an octal number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  var i = start
  var foundDigit = false
  if s[i] == '0' and (s[i+1] == 'o' or s[i+1] == 'O'): inc(i, 2)
  while true: 
    case s[i]
    of '_': discard
    of '0'..'7':
      number = number shl 3 or (ord(s[i]) - ord('0'))
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseIdent*(s: string, ident: var string, start = 0): int =
  ## parses an identifier and stores it in ``ident``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  var i = start
  if s[i] in IdentStartChars:
    inc(i)
    while s[i] in IdentChars: inc(i)
    ident = substr(s, start, i-1)
    result = i-start

proc parseIdent*(s: string, start = 0): string =
  ## parses an identifier and stores it in ``ident``. 
  ## Returns the parsed identifier or an empty string in case of an error.
  result = ""
  var i = start

  if s[i] in IdentStartChars:
    inc(i)
    while s[i] in IdentChars: inc(i)
    
    result = substr(s, start, i-1)

proc parseToken*(s: string, token: var string, validChars: set[char],
                 start = 0): int {.inline, deprecated.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters in `validChars`. 
  ##
  ## **Deprecated since version 0.8.12**: Use ``parseWhile`` instead.
  var i = start
  while s[i] in validChars: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc skipWhitespace*(s: string, start = 0): int {.inline.} =
  ## skips the whitespace starting at ``s[start]``. Returns the number of
  ## skipped characters.
  while s[start+result] in Whitespace: inc(result)

proc skip*(s, token: string, start = 0): int {.inline.} =
  ## skips the `token` starting at ``s[start]``. Returns the length of `token`
  ## or 0 if there was no `token` at ``s[start]``.
  while result < token.len and s[result+start] == token[result]: inc(result)
  if result != token.len: result = 0
  
proc skipIgnoreCase*(s, token: string, start = 0): int =
  ## same as `skip` but case is ignored for token matching.
  while result < token.len and
      toLower(s[result+start]) == toLower(token[result]): inc(result)
  if result != token.len: result = 0
  
proc skipUntil*(s: string, until: set[char], start = 0): int {.inline.} =
  ## Skips all characters until one char from the set `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  while s[result+start] notin until and s[result+start] != '\0': inc(result)

proc skipUntil*(s: string, until: char, start = 0): int {.inline.} =
  ## Skips all characters until the char `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  while s[result+start] != until and s[result+start] != '\0': inc(result)

proc skipWhile*(s: string, toSkip: set[char], start = 0): int {.inline.} =
  ## Skips all characters while one char from the set `token` is found.
  ## Returns number of characters skipped.
  while s[result+start] in toSkip and s[result+start] != '\0': inc(result)

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

proc parseWhile*(s: string, token: var string, validChars: set[char],
                 start = 0): int {.inline.} =
  ## parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters in `validChars`. 
  var i = start
  while s[i] in validChars: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc captureBetween*(s: string, first: char, second = '\0', start = 0): string =
  ## Finds the first occurrence of ``first``, then returns everything from there
  ## up to ``second``(if ``second`` is '\0', then ``first`` is used).
  var i = skipUntil(s, first, start)+1+start
  result = ""
  discard s.parseUntil(result, if second == '\0': first else: second, i)

{.push overflowChecks: on.}
# this must be compiled with overflow checking turned on:
proc rawParseInt(s: string, b: var BiggestInt, start = 0): int =
  var
    sign: BiggestInt = -1
    i = start
  if s[i] == '+': inc(i)
  elif s[i] == '-':
    inc(i)
    sign = 1
  if s[i] in {'0'..'9'}:
    b = 0
    while s[i] in {'0'..'9'}:
      b = b * 10 - (ord(s[i]) - ord('0'))
      inc(i)
      while s[i] == '_': inc(i) # underscores are allowed and ignored
    b = b * sign
    result = i - start
{.pop.} # overflowChecks

proc parseBiggestInt*(s: string, number: var BiggestInt, start = 0): int {.
  rtl, extern: "npuParseBiggestInt", noSideEffect.} =
  ## parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `EOverflow` is raised if an overflow occurs.
  var res: BiggestInt
  # use 'res' for exception safety (don't write to 'number' in case of an
  # overflow exception:
  result = rawParseInt(s, res, start)
  number = res

proc parseInt*(s: string, number: var int, start = 0): int {.
  rtl, extern: "npuParseInt", noSideEffect.} =
  ## parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `EOverflow` is raised if an overflow occurs.
  var res: BiggestInt
  result = parseBiggestInt(s, res, start)
  if (sizeof(int) <= 4) and
      ((res < low(int)) or (res > high(int))):
    raise newException(OverflowError, "overflow")
  elif result != 0:
    number = int(res)

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

{.deprecated: [TInterpolatedKind: InterpolatedKind].}

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
    if s[j] == '$':
      if s[j+1] == '{':
        inc j, 2
        var nesting = 0
        while true:
          case s[j]
          of '{': inc nesting
          of '}':
            if nesting == 0: 
              inc j
              break
            dec nesting
          of '\0':
            raise newException(ValueError, 
              "Expected closing '}': " & substr(s, i, s.high))
          else: discard
          inc j
        inc i, 2 # skip ${
        kind = ikExpr
      elif s[j+1] in IdentStartChars:
        inc j, 2
        while s[j] in IdentChars: inc(j)
        inc i # skip $
        kind = ikVar
      elif s[j+1] == '$':
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
  for k, v in interpolatedFragments("$test{}  $this is ${an{  example}}  "):
    echo "(", k, ", \"", v, "\")"
  var value = 0
  discard parseHex("0x38", value)
  assert value == 56
  discard parseHex("0x34", value)
  assert value == 56 * 256 + 52
  value = -1
  discard parseHex("0x38", value)
  assert value == -200


{.pop.}
