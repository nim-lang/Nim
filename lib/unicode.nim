#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  TUniChar* = int32 ## type that can hold any Unicode character
  TUniChar16* = int16 ##
  
template ones(n) = ((1 shl n)-1)

proc uniCharLen*(s: string): int =
  ## returns the number of Unicode characters of the string `s`.
  var i = 0
  while i < len(s):
    if ord(s[i]) <= 127:
      inc(i)
    elif ord(s[i]) shr 5 == 0b110:
      inc(i, 2)
    elif ord(s[i]) shr 4 == 0b1110:
      inc(i, 3)
    elif ord(s[i]) shr 3 == 0b11110:
      inc(i, 4)
    else:
      assert(false)
    inc(result)

proc uniCharAt*(s: string, i: int): TUniChar =
  if ord(s[i]) <= 127:
    result = ord(s[i])
  elif ord(s[i]) shr 5 == 0b110:
    assert(ord(s[i+1]) shr 6 == 0b10)
    result = (ord(s[i]) and ones(5)) shl 6 or (ord(s[i+1]) and ones(6))
  elif ord(s[i]) shr 4 == 0b1110:
    assert(ord(s[i+1]) shr 6 == 0b10)
    assert(ord(s[i+2]) shr 6 == 0b10)
    result = (ord(s[i]) and ones(4)) shl 12 or
             (ord(s[i+1]) and ones(6)) shl 6 or
             (ord(s[i+2]) and ones(6))
  elif ord(s[i]) shr 3 == 0b11110:
    assert(ord(s[i+1]) shr 6 == 0b10)
    assert(ord(s[i+2]) shr 6 == 0b10)
    assert(ord(s[i+3]) shr 6 == 0b10)
    result = (ord(s[i]) and ones(3)) shl 18 or
             (ord(s[i+1]) and ones(6)) shl 12 or
             (ord(s[i+2]) and ones(6)) shl 6 or
             (ord(s[i+3]) and ones(6))
  else:
    assert(false)

iterator unichars*(s: string): TUniChar =
  ## iterates over any unicode character of the string `s`. Fastest possible
  ## method.
  var
    i = 0
    result: TUniChar
  while i < len(s):
    if ord(s[i]) <= 127:
      result = ord(s[i])
      inc(i)
    elif ord(s[i]) shr 5 == 0b110:
      result = (ord(s[i]) and ones(5)) shl 6 or (ord(s[i+1]) and ones(6))
      inc(i, 2)
    elif ord(s[i]) shr 4 == 0b1110:
      result = (ord(s[i]) and ones(4)) shl 12 or
               (ord(s[i+1]) and ones(6)) shl 6 or
               (ord(s[i+2]) and ones(6))
      inc(i, 3)
    elif ord(s[i]) shr 3 == 0b11110:
      result = (ord(s[i]) and ones(3)) shl 18 or
               (ord(s[i+1]) and ones(6)) shl 12 or
               (ord(s[i+2]) and ones(6)) shl 6 or
               (ord(s[i+3]) and ones(6))
      inc(i, 4)
    else:
      assert(false)
    yield result

proc utf8toLocale*(s: string): string
proc localeToUtf8*(s: string): string

proc utf8toUtf16*(s: string): seq[TUniChar16]
proc utf8toUcs4*(s: string): seq[TUniChar] =
  result = []
  for u in unichars(s): 

proc ucs4ToUtf8(s: seq[TUnichar]): string
proc utf16ToUtf8(s: seq[TUnichar16]): string
proc ucs4toUft16(s: seq[TUnichar]): seq[TUnichar16]
proc uft16toUcs4(s: seq[Tunichar16]): seq[TUnichar]

proc cmpUnicode*(a, b: string): int =
  ## treats `a` and `b` as UTF-8 strings and compares them. Returns:
  ## | < 0 iff a < b
  ## | > 0 iff a > b
  ## | == 0 iff a == b
  ## This routine is useful for sorting UTF-8 strings.
  return -1
  
