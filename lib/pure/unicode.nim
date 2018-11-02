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

type
  RuneImpl = int32 # underlying type of Rune
  Rune* = distinct RuneImpl   ## type that can hold any Unicode character
  Rune16* = distinct int16 ## 16 bit Unicode character

{.deprecated: [TRune: Rune, TRune16: Rune16].}

proc `<=%`*(a, b: Rune): bool = return int(a) <=% int(b)
proc `<%`*(a, b: Rune): bool = return int(a) <% int(b)
proc `==`*(a, b: Rune): bool = return int(a) == int(b)

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

const
  alphaRanges = [
    0x00d8,  0x00f6,  #  -
    0x00f8,  0x01f5,  #  -
    0x0250,  0x02a8,  #  -
    0x038e,  0x03a1,  #  -
    0x03a3,  0x03ce,  #  -
    0x03d0,  0x03d6,  #  -
    0x03e2,  0x03f3,  #  -
    0x0490,  0x04c4,  #  -
    0x0561,  0x0587,  #  -
    0x05d0,  0x05ea,  #  -
    0x05f0,  0x05f2,  #  -
    0x0621,  0x063a,  #  -
    0x0640,  0x064a,  #  -
    0x0671,  0x06b7,  #  -
    0x06ba,  0x06be,  #  -
    0x06c0,  0x06ce,  #  -
    0x06d0,  0x06d3,  #  -
    0x0905,  0x0939,  #  -
    0x0958,  0x0961,  #  -
    0x0985,  0x098c,  #  -
    0x098f,  0x0990,  #  -
    0x0993,  0x09a8,  #  -
    0x09aa,  0x09b0,  #  -
    0x09b6,  0x09b9,  #  -
    0x09dc,  0x09dd,  #  -
    0x09df,  0x09e1,  #  -
    0x09f0,  0x09f1,  #  -
    0x0a05,  0x0a0a,  #  -
    0x0a0f,  0x0a10,  #  -
    0x0a13,  0x0a28,  #  -
    0x0a2a,  0x0a30,  #  -
    0x0a32,  0x0a33,  #  -
    0x0a35,  0x0a36,  #  -
    0x0a38,  0x0a39,  #  -
    0x0a59,  0x0a5c,  #  -
    0x0a85,  0x0a8b,  #  -
    0x0a8f,  0x0a91,  #  -
    0x0a93,  0x0aa8,  #  -
    0x0aaa,  0x0ab0,  #  -
    0x0ab2,  0x0ab3,  #  -
    0x0ab5,  0x0ab9,  #  -
    0x0b05,  0x0b0c,  #  -
    0x0b0f,  0x0b10,  #  -
    0x0b13,  0x0b28,  #  -
    0x0b2a,  0x0b30,  #  -
    0x0b32,  0x0b33,  #  -
    0x0b36,  0x0b39,  #  -
    0x0b5c,  0x0b5d,  #  -
    0x0b5f,  0x0b61,  #  -
    0x0b85,  0x0b8a,  #  -
    0x0b8e,  0x0b90,  #  -
    0x0b92,  0x0b95,  #  -
    0x0b99,  0x0b9a,  #  -
    0x0b9e,  0x0b9f,  #  -
    0x0ba3,  0x0ba4,  #  -
    0x0ba8,  0x0baa,  #  -
    0x0bae,  0x0bb5,  #  -
    0x0bb7,  0x0bb9,  #  -
    0x0c05,  0x0c0c,  #  -
    0x0c0e,  0x0c10,  #  -
    0x0c12,  0x0c28,  #  -
    0x0c2a,  0x0c33,  #  -
    0x0c35,  0x0c39,  #  -
    0x0c60,  0x0c61,  #  -
    0x0c85,  0x0c8c,  #  -
    0x0c8e,  0x0c90,  #  -
    0x0c92,  0x0ca8,  #  -
    0x0caa,  0x0cb3,  #  -
    0x0cb5,  0x0cb9,  #  -
    0x0ce0,  0x0ce1,  #  -
    0x0d05,  0x0d0c,  #  -
    0x0d0e,  0x0d10,  #  -
    0x0d12,  0x0d28,  #  -
    0x0d2a,  0x0d39,  #  -
    0x0d60,  0x0d61,  #  -
    0x0e01,  0x0e30,  #  -
    0x0e32,  0x0e33,  #  -
    0x0e40,  0x0e46,  #  -
    0x0e5a,  0x0e5b,  #  -
    0x0e81,  0x0e82,  #  -
    0x0e87,  0x0e88,  #  -
    0x0e94,  0x0e97,  #  -
    0x0e99,  0x0e9f,  #  -
    0x0ea1,  0x0ea3,  #  -
    0x0eaa,  0x0eab,  #  -
    0x0ead,  0x0eae,  #  -
    0x0eb2,  0x0eb3,  #  -
    0x0ec0,  0x0ec4,  #  -
    0x0edc,  0x0edd,  #  -
    0x0f18,  0x0f19,  #  -
    0x0f40,  0x0f47,  #  -
    0x0f49,  0x0f69,  #  -
    0x10d0,  0x10f6,  #  -
    0x1100,  0x1159,  #  -
    0x115f,  0x11a2,  #  -
    0x11a8,  0x11f9,  #  -
    0x1e00,  0x1e9b,  #  -
    0x1f50,  0x1f57,  #  -
    0x1f80,  0x1fb4,  #  -
    0x1fb6,  0x1fbc,  #  -
    0x1fc2,  0x1fc4,  #  -
    0x1fc6,  0x1fcc,  #  -
    0x1fd0,  0x1fd3,  #  -
    0x1fd6,  0x1fdb,  #  -
    0x1fe0,  0x1fec,  #  -
    0x1ff2,  0x1ff4,  #  -
    0x1ff6,  0x1ffc,  #  -
    0x210a,  0x2113,  #  -
    0x2115,  0x211d,  #  -
    0x2120,  0x2122,  #  -
    0x212a,  0x2131,  #  -
    0x2133,  0x2138,  #  -
    0x3041,  0x3094,  #  -
    0x30a1,  0x30fa,  #  -
    0x3105,  0x312c,  #  -
    0x3131,  0x318e,  #  -
    0x3192,  0x319f,  #  -
    0x3260,  0x327b,  #  -
    0x328a,  0x32b0,  #  -
    0x32d0,  0x32fe,  #  -
    0x3300,  0x3357,  #  -
    0x3371,  0x3376,  #  -
    0x337b,  0x3394,  #  -
    0x3399,  0x339e,  #  -
    0x33a9,  0x33ad,  #  -
    0x33b0,  0x33c1,  #  -
    0x33c3,  0x33c5,  #  -
    0x33c7,  0x33d7,  #  -
    0x33d9,  0x33dd,  #  -
    0x4e00,  0x9fff,  #  -
    0xac00,  0xd7a3,  #  -
    0xf900,  0xfb06,  #  -
    0xfb13,  0xfb17,  #  -
    0xfb1f,  0xfb28,  #  -
    0xfb2a,  0xfb36,  #  -
    0xfb38,  0xfb3c,  #  -
    0xfb40,  0xfb41,  #  -
    0xfb43,  0xfb44,  #  -
    0xfb46,  0xfbb1,  #  -
    0xfbd3,  0xfd3d,  #  -
    0xfd50,  0xfd8f,  #  -
    0xfd92,  0xfdc7,  #  -
    0xfdf0,  0xfdf9,  #  -
    0xfe70,  0xfe72,  #  -
    0xfe76,  0xfefc,  #  -
    0xff66,  0xff6f,  #  -
    0xff71,  0xff9d,  #  -
    0xffa0,  0xffbe,  #  -
    0xffc2,  0xffc7,  #  -
    0xffca,  0xffcf,  #  -
    0xffd2,  0xffd7,  #  -
    0xffda,  0xffdc]  #  -

  alphaSinglets = [
    0x00aa,  #
    0x00b5,  #
    0x00ba,  #
    0x03da,  #
    0x03dc,  #
    0x03de,  #
    0x03e0,  #
    0x06d5,  #
    0x09b2,  #
    0x0a5e,  #
    0x0a8d,  #
    0x0ae0,  #
    0x0b9c,  #
    0x0cde,  #
    0x0e4f,  #
    0x0e84,  #
    0x0e8a,  #
    0x0e8d,  #
    0x0ea5,  #
    0x0ea7,  #
    0x0eb0,  #
    0x0ebd,  #
    0x1fbe,  #
    0x207f,  #
    0x20a8,  #
    0x2102,  #
    0x2107,  #
    0x2124,  #
    0x2126,  #
    0x2128,  #
    0xfb3e,  #
    0xfe74]  #

  spaceRanges = [
    0x0009,  0x000d,  # tab and newline
    0x0020,  0x0020,  # space
    0x0085,  0x0085,  # next line
    0x00a0,  0x00a0,  #
    0x1680,  0x1680,  # Ogham space mark
    0x2000,  0x200b,  # en dash .. zero-width space
    0x200e,  0x200f,  # LTR mark .. RTL mark (pattern whitespace)
    0x2028,  0x2029,  #  -     0x3000,  0x3000,  #
    0x202f,  0x202f,  # narrow no-break space
    0x205f,  0x205f,  # medium mathematical space
    0x3000,  0x3000,  # ideographic space
    0xfeff,  0xfeff]  #

  unicodeSpaces = [
    Rune 0x0009, # tab
    Rune 0x000a, # LF
    Rune 0x000d, # CR
    Rune 0x0020, # space
    Rune 0x0085, # next line
    Rune 0x00a0, # unknown
    Rune 0x1680, # Ogham space mark
    Rune 0x2000, # en dash .. zero-width space
    Rune 0x200e, Rune 0x200f,  # LTR mark .. RTL mark (pattern whitespace)
    Rune 0x2028, Rune 0x2029,  #  -     0x3000,  0x3000,  #
    Rune 0x202f, # narrow no-break space
    Rune 0x205f, # medium mathematical space
    Rune 0x3000, # ideographic space
    Rune 0xfeff] # unknown

  toupperRanges = [
    0x0061,  0x007a, 468,  # a-z A-Z
    0x00e0,  0x00f6, 468,  # - -
    0x00f8,  0x00fe, 468,  # - -
    0x0256,  0x0257, 295,  # - -
    0x0258,  0x0259, 298,  # - -
    0x028a,  0x028b, 283,  # - -
    0x03ad,  0x03af, 463,  # - -
    0x03b1,  0x03c1, 468,  # - -
    0x03c3,  0x03cb, 468,  # - -
    0x03cd,  0x03ce, 437,  # - -
    0x0430,  0x044f, 468,  # - -
    0x0451,  0x045c, 420,  # - -
    0x045e,  0x045f, 420,  # - -
    0x0561,  0x0586, 452,  # - -
    0x1f00,  0x1f07, 508,  # - -
    0x1f10,  0x1f15, 508,  # - -
    0x1f20,  0x1f27, 508,  # - -
    0x1f30,  0x1f37, 508,  # - -
    0x1f40,  0x1f45, 508,  # - -
    0x1f60,  0x1f67, 508,  # - -
    0x1f70,  0x1f71, 574,  # - -
    0x1f72,  0x1f75, 586,  # - -
    0x1f76,  0x1f77, 600,  # - -
    0x1f78,  0x1f79, 628,  # - -
    0x1f7a,  0x1f7b, 612,  # - -
    0x1f7c,  0x1f7d, 626,  # - -
    0x1f80,  0x1f87, 508,  # - -
    0x1f90,  0x1f97, 508,  # - -
    0x1fa0,  0x1fa7, 508,  # - -
    0x1fb0,  0x1fb1, 508,  # - -
    0x1fd0,  0x1fd1, 508,  # - -
    0x1fe0,  0x1fe1, 508,  # - -
    0x2170,  0x217f, 484,  # - -
    0x24d0,  0x24e9, 474,  # - -
    0xff41,  0xff5a, 468]  # - -

  toupperSinglets = [
    0x00ff, 621,  #
    0x0101, 499,  #
    0x0103, 499,  #
    0x0105, 499,  #
    0x0107, 499,  #
    0x0109, 499,  #
    0x010b, 499,  #
    0x010d, 499,  #
    0x010f, 499,  #
    0x0111, 499,  #
    0x0113, 499,  #
    0x0115, 499,  #
    0x0117, 499,  #
    0x0119, 499,  #
    0x011b, 499,  #
    0x011d, 499,  #
    0x011f, 499,  #
    0x0121, 499,  #
    0x0123, 499,  #
    0x0125, 499,  #
    0x0127, 499,  #
    0x0129, 499,  #
    0x012b, 499,  #
    0x012d, 499,  #
    0x012f, 499,  #
    0x0131, 268,  #  I
    0x0133, 499,  #
    0x0135, 499,  #
    0x0137, 499,  #
    0x013a, 499,  #
    0x013c, 499,  #
    0x013e, 499,  #
    0x0140, 499,  #
    0x0142, 499,  #
    0x0144, 499,  #
    0x0146, 499,  #
    0x0148, 499,  #
    0x014b, 499,  #
    0x014d, 499,  #
    0x014f, 499,  #
    0x0151, 499,  #
    0x0153, 499,  #
    0x0155, 499,  #
    0x0157, 499,  #
    0x0159, 499,  #
    0x015b, 499,  #
    0x015d, 499,  #
    0x015f, 499,  #
    0x0161, 499,  #
    0x0163, 499,  #
    0x0165, 499,  #
    0x0167, 499,  #
    0x0169, 499,  #
    0x016b, 499,  #
    0x016d, 499,  #
    0x016f, 499,  #
    0x0171, 499,  #
    0x0173, 499,  #
    0x0175, 499,  #
    0x0177, 499,  #
    0x017a, 499,  #
    0x017c, 499,  #
    0x017e, 499,  #
    0x017f, 200,  #  S
    0x0183, 499,  #
    0x0185, 499,  #
    0x0188, 499,  #
    0x018c, 499,  #
    0x0192, 499,  #
    0x0199, 499,  #
    0x01a1, 499,  #
    0x01a3, 499,  #
    0x01a5, 499,  #
    0x01a8, 499,  #
    0x01ad, 499,  #
    0x01b0, 499,  #
    0x01b4, 499,  #
    0x01b6, 499,  #
    0x01b9, 499,  #
    0x01bd, 499,  #
    0x01c5, 499,  #
    0x01c6, 498,  #
    0x01c8, 499,  #
    0x01c9, 498,  #
    0x01cb, 499,  #
    0x01cc, 498,  #
    0x01ce, 499,  #
    0x01d0, 499,  #
    0x01d2, 499,  #
    0x01d4, 499,  #
    0x01d6, 499,  #
    0x01d8, 499,  #
    0x01da, 499,  #
    0x01dc, 499,  #
    0x01df, 499,  #
    0x01e1, 499,  #
    0x01e3, 499,  #
    0x01e5, 499,  #
    0x01e7, 499,  #
    0x01e9, 499,  #
    0x01eb, 499,  #
    0x01ed, 499,  #
    0x01ef, 499,  #
    0x01f2, 499,  #
    0x01f3, 498,  #
    0x01f5, 499,  #
    0x01fb, 499,  #
    0x01fd, 499,  #
    0x01ff, 499,  #
    0x0201, 499,  #
    0x0203, 499,  #
    0x0205, 499,  #
    0x0207, 499,  #
    0x0209, 499,  #
    0x020b, 499,  #
    0x020d, 499,  #
    0x020f, 499,  #
    0x0211, 499,  #
    0x0213, 499,  #
    0x0215, 499,  #
    0x0217, 499,  #
    0x0253, 290,  #
    0x0254, 294,  #
    0x025b, 297,  #
    0x0260, 295,  #
    0x0263, 293,  #
    0x0268, 291,  #
    0x0269, 289,  #
    0x026f, 289,  #
    0x0272, 287,  #
    0x0283, 282,  #
    0x0288, 282,  #
    0x0292, 281,  #
    0x03ac, 462,  #
    0x03cc, 436,  #
    0x03d0, 438,  #
    0x03d1, 443,  #
    0x03d5, 453,  #
    0x03d6, 446,  #
    0x03e3, 499,  #
    0x03e5, 499,  #
    0x03e7, 499,  #
    0x03e9, 499,  #
    0x03eb, 499,  #
    0x03ed, 499,  #
    0x03ef, 499,  #
    0x03f0, 414,  #
    0x03f1, 420,  #
    0x0461, 499,  #
    0x0463, 499,  #
    0x0465, 499,  #
    0x0467, 499,  #
    0x0469, 499,  #
    0x046b, 499,  #
    0x046d, 499,  #
    0x046f, 499,  #
    0x0471, 499,  #
    0x0473, 499,  #
    0x0475, 499,  #
    0x0477, 499,  #
    0x0479, 499,  #
    0x047b, 499,  #
    0x047d, 499,  #
    0x047f, 499,  #
    0x0481, 499,  #
    0x0491, 499,  #
    0x0493, 499,  #
    0x0495, 499,  #
    0x0497, 499,  #
    0x0499, 499,  #
    0x049b, 499,  #
    0x049d, 499,  #
    0x049f, 499,  #
    0x04a1, 499,  #
    0x04a3, 499,  #
    0x04a5, 499,  #
    0x04a7, 499,  #
    0x04a9, 499,  #
    0x04ab, 499,  #
    0x04ad, 499,  #
    0x04af, 499,  #
    0x04b1, 499,  #
    0x04b3, 499,  #
    0x04b5, 499,  #
    0x04b7, 499,  #
    0x04b9, 499,  #
    0x04bb, 499,  #
    0x04bd, 499,  #
    0x04bf, 499,  #
    0x04c2, 499,  #
    0x04c4, 499,  #
    0x04c8, 499,  #
    0x04cc, 499,  #
    0x04d1, 499,  #
    0x04d3, 499,  #
    0x04d5, 499,  #
    0x04d7, 499,  #
    0x04d9, 499,  #
    0x04db, 499,  #
    0x04dd, 499,  #
    0x04df, 499,  #
    0x04e1, 499,  #
    0x04e3, 499,  #
    0x04e5, 499,  #
    0x04e7, 499,  #
    0x04e9, 499,  #
    0x04eb, 499,  #
    0x04ef, 499,  #
    0x04f1, 499,  #
    0x04f3, 499,  #
    0x04f5, 499,  #
    0x04f9, 499,  #
    0x1e01, 499,  #
    0x1e03, 499,  #
    0x1e05, 499,  #
    0x1e07, 499,  #
    0x1e09, 499,  #
    0x1e0b, 499,  #
    0x1e0d, 499,  #
    0x1e0f, 499,  #
    0x1e11, 499,  #
    0x1e13, 499,  #
    0x1e15, 499,  #
    0x1e17, 499,  #
    0x1e19, 499,  #
    0x1e1b, 499,  #
    0x1e1d, 499,  #
    0x1e1f, 499,  #
    0x1e21, 499,  #
    0x1e23, 499,  #
    0x1e25, 499,  #
    0x1e27, 499,  #
    0x1e29, 499,  #
    0x1e2b, 499,  #
    0x1e2d, 499,  #
    0x1e2f, 499,  #
    0x1e31, 499,  #
    0x1e33, 499,  #
    0x1e35, 499,  #
    0x1e37, 499,  #
    0x1e39, 499,  #
    0x1e3b, 499,  #
    0x1e3d, 499,  #
    0x1e3f, 499,  #
    0x1e41, 499,  #
    0x1e43, 499,  #
    0x1e45, 499,  #
    0x1e47, 499,  #
    0x1e49, 499,  #
    0x1e4b, 499,  #
    0x1e4d, 499,  #
    0x1e4f, 499,  #
    0x1e51, 499,  #
    0x1e53, 499,  #
    0x1e55, 499,  #
    0x1e57, 499,  #
    0x1e59, 499,  #
    0x1e5b, 499,  #
    0x1e5d, 499,  #
    0x1e5f, 499,  #
    0x1e61, 499,  #
    0x1e63, 499,  #
    0x1e65, 499,  #
    0x1e67, 499,  #
    0x1e69, 499,  #
    0x1e6b, 499,  #
    0x1e6d, 499,  #
    0x1e6f, 499,  #
    0x1e71, 499,  #
    0x1e73, 499,  #
    0x1e75, 499,  #
    0x1e77, 499,  #
    0x1e79, 499,  #
    0x1e7b, 499,  #
    0x1e7d, 499,  #
    0x1e7f, 499,  #
    0x1e81, 499,  #
    0x1e83, 499,  #
    0x1e85, 499,  #
    0x1e87, 499,  #
    0x1e89, 499,  #
    0x1e8b, 499,  #
    0x1e8d, 499,  #
    0x1e8f, 499,  #
    0x1e91, 499,  #
    0x1e93, 499,  #
    0x1e95, 499,  #
    0x1ea1, 499,  #
    0x1ea3, 499,  #
    0x1ea5, 499,  #
    0x1ea7, 499,  #
    0x1ea9, 499,  #
    0x1eab, 499,  #
    0x1ead, 499,  #
    0x1eaf, 499,  #
    0x1eb1, 499,  #
    0x1eb3, 499,  #
    0x1eb5, 499,  #
    0x1eb7, 499,  #
    0x1eb9, 499,  #
    0x1ebb, 499,  #
    0x1ebd, 499,  #
    0x1ebf, 499,  #
    0x1ec1, 499,  #
    0x1ec3, 499,  #
    0x1ec5, 499,  #
    0x1ec7, 499,  #
    0x1ec9, 499,  #
    0x1ecb, 499,  #
    0x1ecd, 499,  #
    0x1ecf, 499,  #
    0x1ed1, 499,  #
    0x1ed3, 499,  #
    0x1ed5, 499,  #
    0x1ed7, 499,  #
    0x1ed9, 499,  #
    0x1edb, 499,  #
    0x1edd, 499,  #
    0x1edf, 499,  #
    0x1ee1, 499,  #
    0x1ee3, 499,  #
    0x1ee5, 499,  #
    0x1ee7, 499,  #
    0x1ee9, 499,  #
    0x1eeb, 499,  #
    0x1eed, 499,  #
    0x1eef, 499,  #
    0x1ef1, 499,  #
    0x1ef3, 499,  #
    0x1ef5, 499,  #
    0x1ef7, 499,  #
    0x1ef9, 499,  #
    0x1f51, 508,  #
    0x1f53, 508,  #
    0x1f55, 508,  #
    0x1f57, 508,  #
    0x1fb3, 509,  #
    0x1fc3, 509,  #
    0x1fe5, 507,  #
    0x1ff3, 509]  #

  tolowerRanges = [
    0x0041,  0x005a, 532,  # A-Z a-z
    0x00c0,  0x00d6, 532,  # - -
    0x00d8,  0x00de, 532,  # - -
    0x0189,  0x018a, 705,  # - -
    0x018e,  0x018f, 702,  # - -
    0x01b1,  0x01b2, 717,  # - -
    0x0388,  0x038a, 537,  # - -
    0x038e,  0x038f, 563,  # - -
    0x0391,  0x03a1, 532,  # - -
    0x03a3,  0x03ab, 532,  # - -
    0x0401,  0x040c, 580,  # - -
    0x040e,  0x040f, 580,  # - -
    0x0410,  0x042f, 532,  # - -
    0x0531,  0x0556, 548,  # - -
    0x10a0,  0x10c5, 548,  # - -
    0x1f08,  0x1f0f, 492,  # - -
    0x1f18,  0x1f1d, 492,  # - -
    0x1f28,  0x1f2f, 492,  # - -
    0x1f38,  0x1f3f, 492,  # - -
    0x1f48,  0x1f4d, 492,  # - -
    0x1f68,  0x1f6f, 492,  # - -
    0x1f88,  0x1f8f, 492,  # - -
    0x1f98,  0x1f9f, 492,  # - -
    0x1fa8,  0x1faf, 492,  # - -
    0x1fb8,  0x1fb9, 492,  # - -
    0x1fba,  0x1fbb, 426,  # - -
    0x1fc8,  0x1fcb, 414,  # - -
    0x1fd8,  0x1fd9, 492,  # - -
    0x1fda,  0x1fdb, 400,  # - -
    0x1fe8,  0x1fe9, 492,  # - -
    0x1fea,  0x1feb, 388,  # - -
    0x1ff8,  0x1ff9, 372,  # - -
    0x1ffa,  0x1ffb, 374,  # - -
    0x2160,  0x216f, 516,  # - -
    0x24b6,  0x24cf, 526,  # - -
    0xff21,  0xff3a, 532]  # - -

  tolowerSinglets = [
    0x0100, 501,  #
    0x0102, 501,  #
    0x0104, 501,  #
    0x0106, 501,  #
    0x0108, 501,  #
    0x010a, 501,  #
    0x010c, 501,  #
    0x010e, 501,  #
    0x0110, 501,  #
    0x0112, 501,  #
    0x0114, 501,  #
    0x0116, 501,  #
    0x0118, 501,  #
    0x011a, 501,  #
    0x011c, 501,  #
    0x011e, 501,  #
    0x0120, 501,  #
    0x0122, 501,  #
    0x0124, 501,  #
    0x0126, 501,  #
    0x0128, 501,  #
    0x012a, 501,  #
    0x012c, 501,  #
    0x012e, 501,  #
    0x0130, 301,  #  i
    0x0132, 501,  #
    0x0134, 501,  #
    0x0136, 501,  #
    0x0139, 501,  #
    0x013b, 501,  #
    0x013d, 501,  #
    0x013f, 501,  #
    0x0141, 501,  #
    0x0143, 501,  #
    0x0145, 501,  #
    0x0147, 501,  #
    0x014a, 501,  #
    0x014c, 501,  #
    0x014e, 501,  #
    0x0150, 501,  #
    0x0152, 501,  #
    0x0154, 501,  #
    0x0156, 501,  #
    0x0158, 501,  #
    0x015a, 501,  #
    0x015c, 501,  #
    0x015e, 501,  #
    0x0160, 501,  #
    0x0162, 501,  #
    0x0164, 501,  #
    0x0166, 501,  #
    0x0168, 501,  #
    0x016a, 501,  #
    0x016c, 501,  #
    0x016e, 501,  #
    0x0170, 501,  #
    0x0172, 501,  #
    0x0174, 501,  #
    0x0176, 501,  #
    0x0178, 379,  #
    0x0179, 501,  #
    0x017b, 501,  #
    0x017d, 501,  #
    0x0181, 710,  #
    0x0182, 501,  #
    0x0184, 501,  #
    0x0186, 706,  #
    0x0187, 501,  #
    0x018b, 501,  #
    0x0190, 703,  #
    0x0191, 501,  #
    0x0193, 705,  #
    0x0194, 707,  #
    0x0196, 711,  #
    0x0197, 709,  #
    0x0198, 501,  #
    0x019c, 711,  #
    0x019d, 713,  #
    0x01a0, 501,  #
    0x01a2, 501,  #
    0x01a4, 501,  #
    0x01a7, 501,  #
    0x01a9, 718,  #
    0x01ac, 501,  #
    0x01ae, 718,  #
    0x01af, 501,  #
    0x01b3, 501,  #
    0x01b5, 501,  #
    0x01b7, 719,  #
    0x01b8, 501,  #
    0x01bc, 501,  #
    0x01c4, 502,  #
    0x01c5, 501,  #
    0x01c7, 502,  #
    0x01c8, 501,  #
    0x01ca, 502,  #
    0x01cb, 501,  #
    0x01cd, 501,  #
    0x01cf, 501,  #
    0x01d1, 501,  #
    0x01d3, 501,  #
    0x01d5, 501,  #
    0x01d7, 501,  #
    0x01d9, 501,  #
    0x01db, 501,  #
    0x01de, 501,  #
    0x01e0, 501,  #
    0x01e2, 501,  #
    0x01e4, 501,  #
    0x01e6, 501,  #
    0x01e8, 501,  #
    0x01ea, 501,  #
    0x01ec, 501,  #
    0x01ee, 501,  #
    0x01f1, 502,  #
    0x01f2, 501,  #
    0x01f4, 501,  #
    0x01fa, 501,  #
    0x01fc, 501,  #
    0x01fe, 501,  #
    0x0200, 501,  #
    0x0202, 501,  #
    0x0204, 501,  #
    0x0206, 501,  #
    0x0208, 501,  #
    0x020a, 501,  #
    0x020c, 501,  #
    0x020e, 501,  #
    0x0210, 501,  #
    0x0212, 501,  #
    0x0214, 501,  #
    0x0216, 501,  #
    0x0386, 538,  #
    0x038c, 564,  #
    0x03e2, 501,  #
    0x03e4, 501,  #
    0x03e6, 501,  #
    0x03e8, 501,  #
    0x03ea, 501,  #
    0x03ec, 501,  #
    0x03ee, 501,  #
    0x0460, 501,  #
    0x0462, 501,  #
    0x0464, 501,  #
    0x0466, 501,  #
    0x0468, 501,  #
    0x046a, 501,  #
    0x046c, 501,  #
    0x046e, 501,  #
    0x0470, 501,  #
    0x0472, 501,  #
    0x0474, 501,  #
    0x0476, 501,  #
    0x0478, 501,  #
    0x047a, 501,  #
    0x047c, 501,  #
    0x047e, 501,  #
    0x0480, 501,  #
    0x0490, 501,  #
    0x0492, 501,  #
    0x0494, 501,  #
    0x0496, 501,  #
    0x0498, 501,  #
    0x049a, 501,  #
    0x049c, 501,  #
    0x049e, 501,  #
    0x04a0, 501,  #
    0x04a2, 501,  #
    0x04a4, 501,  #
    0x04a6, 501,  #
    0x04a8, 501,  #
    0x04aa, 501,  #
    0x04ac, 501,  #
    0x04ae, 501,  #
    0x04b0, 501,  #
    0x04b2, 501,  #
    0x04b4, 501,  #
    0x04b6, 501,  #
    0x04b8, 501,  #
    0x04ba, 501,  #
    0x04bc, 501,  #
    0x04be, 501,  #
    0x04c1, 501,  #
    0x04c3, 501,  #
    0x04c7, 501,  #
    0x04cb, 501,  #
    0x04d0, 501,  #
    0x04d2, 501,  #
    0x04d4, 501,  #
    0x04d6, 501,  #
    0x04d8, 501,  #
    0x04da, 501,  #
    0x04dc, 501,  #
    0x04de, 501,  #
    0x04e0, 501,  #
    0x04e2, 501,  #
    0x04e4, 501,  #
    0x04e6, 501,  #
    0x04e8, 501,  #
    0x04ea, 501,  #
    0x04ee, 501,  #
    0x04f0, 501,  #
    0x04f2, 501,  #
    0x04f4, 501,  #
    0x04f8, 501,  #
    0x1e00, 501,  #
    0x1e02, 501,  #
    0x1e04, 501,  #
    0x1e06, 501,  #
    0x1e08, 501,  #
    0x1e0a, 501,  #
    0x1e0c, 501,  #
    0x1e0e, 501,  #
    0x1e10, 501,  #
    0x1e12, 501,  #
    0x1e14, 501,  #
    0x1e16, 501,  #
    0x1e18, 501,  #
    0x1e1a, 501,  #
    0x1e1c, 501,  #
    0x1e1e, 501,  #
    0x1e20, 501,  #
    0x1e22, 501,  #
    0x1e24, 501,  #
    0x1e26, 501,  #
    0x1e28, 501,  #
    0x1e2a, 501,  #
    0x1e2c, 501,  #
    0x1e2e, 501,  #
    0x1e30, 501,  #
    0x1e32, 501,  #
    0x1e34, 501,  #
    0x1e36, 501,  #
    0x1e38, 501,  #
    0x1e3a, 501,  #
    0x1e3c, 501,  #
    0x1e3e, 501,  #
    0x1e40, 501,  #
    0x1e42, 501,  #
    0x1e44, 501,  #
    0x1e46, 501,  #
    0x1e48, 501,  #
    0x1e4a, 501,  #
    0x1e4c, 501,  #
    0x1e4e, 501,  #
    0x1e50, 501,  #
    0x1e52, 501,  #
    0x1e54, 501,  #
    0x1e56, 501,  #
    0x1e58, 501,  #
    0x1e5a, 501,  #
    0x1e5c, 501,  #
    0x1e5e, 501,  #
    0x1e60, 501,  #
    0x1e62, 501,  #
    0x1e64, 501,  #
    0x1e66, 501,  #
    0x1e68, 501,  #
    0x1e6a, 501,  #
    0x1e6c, 501,  #
    0x1e6e, 501,  #
    0x1e70, 501,  #
    0x1e72, 501,  #
    0x1e74, 501,  #
    0x1e76, 501,  #
    0x1e78, 501,  #
    0x1e7a, 501,  #
    0x1e7c, 501,  #
    0x1e7e, 501,  #
    0x1e80, 501,  #
    0x1e82, 501,  #
    0x1e84, 501,  #
    0x1e86, 501,  #
    0x1e88, 501,  #
    0x1e8a, 501,  #
    0x1e8c, 501,  #
    0x1e8e, 501,  #
    0x1e90, 501,  #
    0x1e92, 501,  #
    0x1e94, 501,  #
    0x1ea0, 501,  #
    0x1ea2, 501,  #
    0x1ea4, 501,  #
    0x1ea6, 501,  #
    0x1ea8, 501,  #
    0x1eaa, 501,  #
    0x1eac, 501,  #
    0x1eae, 501,  #
    0x1eb0, 501,  #
    0x1eb2, 501,  #
    0x1eb4, 501,  #
    0x1eb6, 501,  #
    0x1eb8, 501,  #
    0x1eba, 501,  #
    0x1ebc, 501,  #
    0x1ebe, 501,  #
    0x1ec0, 501,  #
    0x1ec2, 501,  #
    0x1ec4, 501,  #
    0x1ec6, 501,  #
    0x1ec8, 501,  #
    0x1eca, 501,  #
    0x1ecc, 501,  #
    0x1ece, 501,  #
    0x1ed0, 501,  #
    0x1ed2, 501,  #
    0x1ed4, 501,  #
    0x1ed6, 501,  #
    0x1ed8, 501,  #
    0x1eda, 501,  #
    0x1edc, 501,  #
    0x1ede, 501,  #
    0x1ee0, 501,  #
    0x1ee2, 501,  #
    0x1ee4, 501,  #
    0x1ee6, 501,  #
    0x1ee8, 501,  #
    0x1eea, 501,  #
    0x1eec, 501,  #
    0x1eee, 501,  #
    0x1ef0, 501,  #
    0x1ef2, 501,  #
    0x1ef4, 501,  #
    0x1ef6, 501,  #
    0x1ef8, 501,  #
    0x1f59, 492,  #
    0x1f5b, 492,  #
    0x1f5d, 492,  #
    0x1f5f, 492,  #
    0x1fbc, 491,  #
    0x1fcc, 491,  #
    0x1fec, 493,  #
    0x1ffc, 491]  #

  toTitleSinglets = [
    0x01c4, 501,  #
    0x01c6, 499,  #
    0x01c7, 501,  #
    0x01c9, 499,  #
    0x01ca, 501,  #
    0x01cc, 499,  #
    0x01f1, 501,  #
    0x01f3, 499]  #

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
  ## Converts ``c`` into lower case. This works for any Unicode character.
  ## If possible, prefer ``toLower`` over ``toUpper``.
  var c = RuneImpl(c)
  var p = binarySearch(c, tolowerRanges, len(tolowerRanges) div 3, 3)
  if p >= 0 and c >= tolowerRanges[p] and c <= tolowerRanges[p+1]:
    return Rune(c + tolowerRanges[p+2] - 500)
  p = binarySearch(c, tolowerSinglets, len(tolowerSinglets) div 2, 2)
  if p >= 0 and c == tolowerSinglets[p]:
    return Rune(c + tolowerSinglets[p+1] - 500)
  return Rune(c)

proc toUpper*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into upper case. This works for any Unicode character.
  ## If possible, prefer ``toLower`` over ``toUpper``.
  var c = RuneImpl(c)
  var p = binarySearch(c, toupperRanges, len(toupperRanges) div 3, 3)
  if p >= 0 and c >= toupperRanges[p] and c <= toupperRanges[p+1]:
    return Rune(c + toupperRanges[p+2] - 500)
  p = binarySearch(c, toupperSinglets, len(toupperSinglets) div 2, 2)
  if p >= 0 and c == toupperSinglets[p]:
    return Rune(c + toupperSinglets[p+1] - 500)
  return Rune(c)

proc toTitle*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` to title case
  var c = RuneImpl(c)
  var p = binarySearch(c, toTitleSinglets, len(toTitleSinglets) div 2, 2)
  if p >= 0 and c == toTitleSinglets[p]:
    return Rune(c + toTitleSinglets[p+1] - 500)
  return Rune(c)

proc isLower*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a lower case Unicode character.
  ## If possible, prefer ``isLower`` over ``isUpper``.
  var c = RuneImpl(c)
  # Note: toUpperRanges is correct here!
  var p = binarySearch(c, toupperRanges, len(toupperRanges) div 3, 3)
  if p >= 0 and c >= toupperRanges[p] and c <= toupperRanges[p+1]:
    return true
  p = binarySearch(c, toupperSinglets, len(toupperSinglets) div 2, 2)
  if p >= 0 and c == toupperSinglets[p]:
    return true

proc isUpper*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a upper case Unicode character.
  ## If possible, prefer ``isLower`` over ``isUpper``.
  var c = RuneImpl(c)
  # Note: toLowerRanges is correct here!
  var p = binarySearch(c, tolowerRanges, len(tolowerRanges) div 3, 3)
  if p >= 0 and c >= tolowerRanges[p] and c <= tolowerRanges[p+1]:
    return true
  p = binarySearch(c, tolowerSinglets, len(tolowerSinglets) div 2, 2)
  if p >= 0 and c == tolowerSinglets[p]:
    return true

proc isAlpha*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is an *alpha* Unicode character (i.e., a letter)
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
  ## Returns true iff ``c`` is a Unicode titlecase character
  return isUpper(c) and isLower(c)

proc isWhiteSpace*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a Unicode whitespace character
  var c = RuneImpl(c)
  var p = binarySearch(c, spaceRanges, len(spaceRanges) div 2, 2)
  if p >= 0 and c >= spaceRanges[p] and c <= spaceRanges[p+1]:
    return true

proc isCombining*(c: Rune): bool {.rtl, extern: "nuc$1", procvar.} =
  ## Returns true iff ``c`` is a Unicode combining character
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

proc isLower*(s: string, skipNonAlpha: bool): bool {.
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".} =
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

proc isUpper*(s: string, skipNonAlpha: bool): bool {.
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".} =
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
  rtl, extern: "nuc$1".} =
  ## Swaps the case of unicode characters in `s`
  ##
  ## Returns a new string such that the cases of all unicode characters
  ## are swapped if possible

  var
    i = 0
    lastIndex = 0
    rune: Rune

  result = newString(len(s))

  while i < len(s):
    lastIndex = i

    fastRuneAt(s, i, rune)

    if rune.isUpper():
      rune = rune.toLower()
    elif rune.isLower():
      rune = rune.toUpper()

    rune.fastToUTF8Copy(result, lastIndex)

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
  rtl, extern: "nuc$1Str",
  deprecated: "Deprecated since version 0.20 since its semantics are unclear".}=
  ## Checks whether or not `s` is a unicode title.
  ##
  ## Returns true if the first character in each word inside `s`
  ## are upper case and there is at least one character in `s`.
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

proc size*(r: Rune): int {.noSideEffect.} =
  ## Returns the number of bytes the rune ``r`` takes.
  let v = r.uint32
  if v <= 0x007F: result = 1
  elif v <= 0x07FF: result = 2
  elif v <= 0xFFFF: result = 3
  elif v <= 0x1FFFFF: result = 4
  elif v <= 0x3FFFFFF: result = 5
  elif v <= 0x7FFFFFFF: result = 6
  else: result = 1

# --------- Private templates for different split separators -----------
proc stringHasSep(s: string, index: int, seps: openarray[Rune]): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return seps.contains(rune)

proc stringHasSep(s: string, index: int, sep: Rune): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return sep == rune

template splitCommon(s, sep, maxsplit: untyped, sepLen: int = -1) =
  ## Common code for split procedures
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
          inc(last, runeLenAt(s, last))
      if splits == 0: last = len(s)
      yield s[first .. (last - 1)]
      if splits == 0: break
      dec(splits)
      when sep is Rune:
        inc(last, sepLen)
      else:
        inc(last, if last < len(s): runeLenAt(s, last) else: 1)

iterator split*(s: string, seps: openarray[Rune] = unicodeSpaces,
  maxsplit: int = -1): string =
  ## Splits the unicode string `s` into substrings using a group of separators.
  ##
  ## Substrings are separated by a substring containing only `seps`.
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
  ## Splits a unicode string at whitespace runes
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
  ## Splits the unicode string `s` into substrings using a single separator.
  ##
  ## Substrings are separated by the rune `sep`.
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

proc split*(s: string, seps: openarray[Rune] = unicodeSpaces, maxsplit: int = -1): seq[string] {.
  noSideEffect, rtl, extern: "nucSplitRunes".} =
  ## The same as the `split iterator <#split.i,string,openarray[Rune]>`_, but is a
  ## proc that returns a sequence of substrings.
  accResult(split(s, seps, maxsplit))

proc split*(s: string, sep: Rune, maxsplit: int = -1): seq[string] {.noSideEffect,
  rtl, extern: "nucSplitRune".} =
  ## The same as the `split iterator <#split.i,string,Rune>`_, but is a proc
  ## that returns a sequence of substrings.
  accResult(split(s, sep, maxsplit))

proc strip*(s: string, leading = true, trailing = true,
            runes: openarray[Rune] = unicodeSpaces): string {.noSideEffect,
            rtl, extern: "nucStrip".} =
  ## Strips leading or trailing `runes` from `s` and returns
  ## the resulting string.
  ##
  ## If `leading` is true, leading `runes` are stripped.
  ## If `trailing` is true, trailing `runes` are stripped.
  ## If both are false, the string is returned unchanged.
  var
    s_i = 0 ## starting index into string ``s``
    e_i = len(s) - 1 ## ending index into ``s``, where the last ``Rune`` starts
  if leading:
    var
      i = 0
      l_i: int ## value of ``s_i`` at the beginning of the iteration
      rune: Rune
    while i < len(s):
      l_i = i
      fastRuneAt(s, i, rune)
      s_i = i # Assume to start from next rune
      if not runes.contains(rune):
        s_i = l_i # Go back to where the current rune starts
        break
  if trailing:
    var
      i = e_i
      l_i: int
      rune: Rune
    while i >= 0:
      l_i = i
      fastRuneAt(s, l_i, rune)
      var p_i = i - 1
      while p_i >= 0:
        var
          p_i_end = p_i
          p_rune: Rune
        fastRuneAt(s, p_i_end, p_rune)
        if p_i_end < l_i: break
        i = p_i
        rune = p_rune
        dec(p_i)
      if not runes.contains(rune):
        e_i = l_i - 1
        break
      dec(i)
  let newLen = e_i - s_i
  result = newStringOfCap(newLen)
  if e_i > s_i:
    result.add s[s_i .. e_i]

proc repeat*(c: Rune, count: Natural): string {.noSideEffect,
  rtl, extern: "nucRepeatRune".} =
  ## Returns a string of `count` Runes `c`.
  ##
  ## The returned string will have a rune-length of `count`.
  let s = $c
  result = newStringOfCap(count * s.len)
  for i in 0 ..< count:
    result.add s

proc align*(s: string, count: Natural, padding = ' '.Rune): string {.
  noSideEffect, rtl, extern: "nucAlignString".} =
  ## Aligns a unicode string `s` with `padding`, so that it has a rune-length
  ## of `count`.
  ##
  ## `padding` characters (by default spaces) are added before `s` resulting in
  ## right alignment. If ``s.runelen >= count``, no spaces are added and `s` is
  ## returned unchanged. If you need to left align a string use the `alignLeft
  ## proc <#alignLeft>`_.
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
  ## Left-Aligns a unicode string `s` with `padding`, so that it has a
  ## rune-length of `count`.
  ##
  ## `padding` characters (by default spaces) are added after `s` resulting in
  ## left alignment. If ``s.runelen >= count``, no spaces are added and `s` is
  ## returned unchanged. If you need to right align a string use the `align
  ## proc <#align>`_.
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

  doAssert(not isUpper(' '.Rune))

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
