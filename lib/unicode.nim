#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides a way to handle various Unicode (or other) encodings.

type
  TUniChar* = int32 ## type that can hold any Unicode character
  TUniChar16* = int16 ## 16 bit Unicode character
  
template ones(n) = ((1 shl n)-1)

proc uniCharLen*(s: string): int =
  ## returns the number of Unicode characters of the string `s`.
  var i = 0
  while i < len(s):
    if ord(s[i]) <= 127: inc(i)
    elif ord(s[i]) shr 5 == 0b110: inc(i, 2)
    elif ord(s[i]) shr 4 == 0b1110: inc(i, 3)
    elif ord(s[i]) shr 3 == 0b11110: inc(i, 4)
    else: assert(false)
    inc(result)

proc uniCharAt*(s: string, i: int): TUniChar =
  ## returns the unicode character in `s` at byte index `i`
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
  ## iterates over any unicode character of the string `s`.
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
    
type
  TCharacterSet = enum
    cs8859_1, cs8859_2
    
const
  characterSetToName: array [TCharacterSet, string] = [
    "ISO/IEC 8859-1:1998",
    "ISO 8859-2:1999",
    "",
    ""
    ]
    
  cs8859_2toUnicode: array [0xA1..0xff, TUniChar16] = [
    0x0104'i16, 0x02D8'i16, 0x0141'i16, 0x00A4'i16, 0x013D'i16, 0x015A'i16,  
    0x00A7'i16, 0x00A8'i16, 0x0160'i16, 0x015E'i16, 0x0164'i16, 0x0179'i16,  
    0x00AD'i16, 0x017D'i16, 0x017B'i16, 0x00B0'i16, 0x0105'i16, 0x02DB'i16,  
    0x0142'i16, 0x00B4'i16, 0x013E'i16, 0x015B'i16, 0x02C7'i16, 0x00B8'i16,  
    0x0161'i16, 0x015F'i16, 0x0165'i16, 0x017A'i16, 0x02DD'i16, 0x017E'i16,  
    0x017C'i16, 0x0154'i16, 0x00C1'i16, 0x00C2'i16, 0x0102'i16, 0x00C4'i16,  
    0x0139'i16, 0x0106'i16, 0x00C7'i16, 0x010C'i16, 0x00C9'i16, 0x0118'i16,  
    0x00CB'i16, 0x011A'i16, 0x00CD'i16, 0x00CE'i16, 0x010E'i16, 0x0110'i16,  
    0x0143'i16, 0x0147'i16, 0x00D3'i16, 0x00D4'i16, 0x0150'i16, 0x00D6'i16,  
    0x00D7'i16, 0x0158'i16, 0x016E'i16, 0x00DA'i16, 0x0170'i16, 0x00DC'i16,  
    0x00DD'i16, 0x0162'i16, 0x00DF'i16, 0x0155'i16, 0x00E1'i16, 0x00E2'i16,  
    0x0103'i16, 0x00E4'i16, 0x013A'i16, 0x0107'i16, 0x00E7'i16, 0x010D'i16,  
    0x00E9'i16, 0x0119'i16, 0x00EB'i16, 0x011B'i16, 0x00ED'i16, 0x00EE'i16,  
    0x010F'i16, 0x0111'i16, 0x0144'i16, 0x0148'i16, 0x00F3'i16, 0x00F4'i16,  
    0x0151'i16, 0x00F6'i16, 0x00F7'i16, 0x0159'i16, 0x016F'i16, 0x00FA'i16,  
    0x0171'i16, 0x00FC'i16, 0x00FD'i16, 0x0163'i16, 0x02D9'i16]
    
proc searchTable(tab: openarray[TUniChar16], u: TUniChar16): int8 = 
  var idx = find(tab, u)
  assert(idx > 0)
  result = toU8(idx)
    
proc csToUnicode(cs: TCharacterSet, c: int8): TUniChar16 = 
  case cs
  of cs8859_1: result = ze16(c) # no table lookup necessary
  of cs8859_2: 
    if c <=% 0xA0'i8: 
      result = ze16(c)
    else:
      result = cs8859_2toUnicode[ze(c)]

proc unicodeToCS(cs: TCharacterSet, u: TUniChar16): int8 = 
  case cs
  of cs8859_1: result = toU8(u) # no table lookup necessary
  of cs8859_2:
    if u <=% 0x00A0'i16: 
      result = toU8(u)
    else:
      result = searchTable(cs8859_2toUnicode, u) +% 0xA1'8

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
  
