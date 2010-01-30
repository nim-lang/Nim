#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Helpers for parsing.

import strutils

proc parseHex*(s: string, number: var int, start = 0): int = 
  ## parses a hexadecimal number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  var i = start
  var foundDigit = false
  if s[i] == '0' and (s[i+1] == 'x' or s[i+1] == 'X'): inc(i, 2)
  elif s[i] == '#': inc(i)
  while true: 
    case s[i]
    of '_': nil
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

proc parseIdent*(s: string, ident: var string, start = 0): int =
  ## parses an identifier and stores it in ``ident``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  var i = start
  if s[i] in IdentStartChars:
    inc(i)
    while s[i] in IdentChars: inc(i)
    ident = copy(s, start, i-1)
    result = i-start

proc skipWhitespace*(s: string, start = 0): int {.inline.} =
  while s[start+result] in Whitespace: inc(result)

proc skip*(s, token: string, start = 0): int =
  while result < token.len and s[result+start] == token[result]: inc(result)
  if result != token.len: result = 0
  
proc skipIgnoreCase*(s, token: string, start = 0): int =
  while result < token.len and
      toLower(s[result+start]) == toLower(token[result]): inc(result)
  if result != token.len: result = 0  

proc parseBiggestInt*(s: string, number: var biggestInt, start = 0): int =
  assert(false) # to implement

proc parseBiggestFloat*(s: string, number: var biggestFloat, start = 0): int = 
  assert(false) # to implement
