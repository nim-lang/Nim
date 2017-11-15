#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides support to handle the Unicode UTF-8 encoding.

from algorithm import reverse

{.deadCodeElim: on.}

include "system/inclrtl"

type
  RuneImpl = int32 # underlying type of Rune
  Rune* = distinct RuneImpl   ## type that can hold any Unicode character
  Rune16* = distinct int16 ## 16 bit Unicode character

{.deprecated: [TRune: Rune, TRune16: Rune16].}

proc `<=`(a, b: Rune): bool = return a.int32 <= b.int32
proc `<=`(a: RuneImpl, b: Rune): bool = return a.int32 <= b.int32
proc `<=`(a: Rune, b: RuneImpl): bool = return a.int32 <= b.int32
proc `==`(a: RuneImpl, b: Rune): bool = return a.int32 == b.int32
proc `==`(a: Rune, b: RuneImpl): bool = return a.int32 == b.int32

proc `<=%`*(a, b: Rune): bool = return int(a) <=% int(b)
proc `<%`*(a, b: Rune): bool = return int(a) <% int(b)
proc `==`*(a, b: Rune): bool = return int(a) == int(b)

template ones(n: untyped): untyped = ((1 shl n)-1)

proc size*(r: Rune): int {.noSideEffect.} =
  ## Returns the number of bytes the rune ``r`` takes
  let v = r.int32
  if ord(v) <=% 127: result = 1
  elif ord(v) shr 5 == 0b110: result = 2
  elif ord(v) shr 4 == 0b1110: result = 3
  elif ord(v) shr 3 == 0b11110: result = 4
  elif ord(v) shr 2 == 0b111110: result = 5
  elif ord(v) shr 1 == 0b1111110: result = 6
  else: result = 1

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

proc runeLenAt*(s: string, i: Natural): int =
  ## Returns the number of bytes the rune starting at ``s[i]`` takes
  var r: Rune
  s.fastRuneAt(i.int, r, doInc = false)
  result = r.size()

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

proc asRune*(s: static[string]): Rune =
  ## Compile-time conversion proc for converting string literals to a Rune
  ## value. Returns the first Rune of the specified string.
  ##
  ## Shortcuts code like ``"å".runeAt(0)`` to ``"å".asRune`` and returns a
  ## compile-time constant.
  if len(s) == 0: '\0'.Rune
  else: s.runeAt(0)

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
    return (-a, rev.int - a)
  return (x, -a + rev.int)

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
      result = s[o.. s.len-1]
    elif len < 0:
      let e = rl + len
      if e < 0:
        result = ""
      else:
        result = s[o.. runeOffset(s, e-(rl+pos) , o)-1]
    else:
      result = s[o.. runeOffset(s, len, o)-1]
  else:
    let o = runeOffset(s, pos)
    if o < 0:
      result = ""
    elif len == int.high:
      result = s[o.. s.len-1]
    elif len < 0:
      let (e, rl) = runeReverseOffset(s, -len)
      discard rl
      if e <= 0:
        result = ""
      else:
        result = s[o.. e-1]
    else:
      var e = runeOffset(s, len, o)
      if e < 0:
        e = s.len
      result = s[o.. e-1]

const
  alphaRanges = [
    0x00d8.Rune,  0x00f6.Rune,  #  -
    0x00f8.Rune,  0x01f5.Rune,  #  -
    0x0250.Rune,  0x02a8.Rune,  #  -
    0x038e.Rune,  0x03a1.Rune,  #  -
    0x03a3.Rune,  0x03ce.Rune,  #  -
    0x03d0.Rune,  0x03d6.Rune,  #  -
    0x03e2.Rune,  0x03f3.Rune,  #  -
    0x0490.Rune,  0x04c4.Rune,  #  -
    0x0561.Rune,  0x0587.Rune,  #  -
    0x05d0.Rune,  0x05ea.Rune,  #  -
    0x05f0.Rune,  0x05f2.Rune,  #  -
    0x0621.Rune,  0x063a.Rune,  #  -
    0x0640.Rune,  0x064a.Rune,  #  -
    0x0671.Rune,  0x06b7.Rune,  #  -
    0x06ba.Rune,  0x06be.Rune,  #  -
    0x06c0.Rune,  0x06ce.Rune,  #  -
    0x06d0.Rune,  0x06d3.Rune,  #  -
    0x0905.Rune,  0x0939.Rune,  #  -
    0x0958.Rune,  0x0961.Rune,  #  -
    0x0985.Rune,  0x098c.Rune,  #  -
    0x098f.Rune,  0x0990.Rune,  #  -
    0x0993.Rune,  0x09a8.Rune,  #  -
    0x09aa.Rune,  0x09b0.Rune,  #  -
    0x09b6.Rune,  0x09b9.Rune,  #  -
    0x09dc.Rune,  0x09dd.Rune,  #  -
    0x09df.Rune,  0x09e1.Rune,  #  -
    0x09f0.Rune,  0x09f1.Rune,  #  -
    0x0a05.Rune,  0x0a0a.Rune,  #  -
    0x0a0f.Rune,  0x0a10.Rune,  #  -
    0x0a13.Rune,  0x0a28.Rune,  #  -
    0x0a2a.Rune,  0x0a30.Rune,  #  -
    0x0a32.Rune,  0x0a33.Rune,  #  -
    0x0a35.Rune,  0x0a36.Rune,  #  -
    0x0a38.Rune,  0x0a39.Rune,  #  -
    0x0a59.Rune,  0x0a5c.Rune,  #  -
    0x0a85.Rune,  0x0a8b.Rune,  #  -
    0x0a8f.Rune,  0x0a91.Rune,  #  -
    0x0a93.Rune,  0x0aa8.Rune,  #  -
    0x0aaa.Rune,  0x0ab0.Rune,  #  -
    0x0ab2.Rune,  0x0ab3.Rune,  #  -
    0x0ab5.Rune,  0x0ab9.Rune,  #  -
    0x0b05.Rune,  0x0b0c.Rune,  #  -
    0x0b0f.Rune,  0x0b10.Rune,  #  -
    0x0b13.Rune,  0x0b28.Rune,  #  -
    0x0b2a.Rune,  0x0b30.Rune,  #  -
    0x0b32.Rune,  0x0b33.Rune,  #  -
    0x0b36.Rune,  0x0b39.Rune,  #  -
    0x0b5c.Rune,  0x0b5d.Rune,  #  -
    0x0b5f.Rune,  0x0b61.Rune,  #  -
    0x0b85.Rune,  0x0b8a.Rune,  #  -
    0x0b8e.Rune,  0x0b90.Rune,  #  -
    0x0b92.Rune,  0x0b95.Rune,  #  -
    0x0b99.Rune,  0x0b9a.Rune,  #  -
    0x0b9e.Rune,  0x0b9f.Rune,  #  -
    0x0ba3.Rune,  0x0ba4.Rune,  #  -
    0x0ba8.Rune,  0x0baa.Rune,  #  -
    0x0bae.Rune,  0x0bb5.Rune,  #  -
    0x0bb7.Rune,  0x0bb9.Rune,  #  -
    0x0c05.Rune,  0x0c0c.Rune,  #  -
    0x0c0e.Rune,  0x0c10.Rune,  #  -
    0x0c12.Rune,  0x0c28.Rune,  #  -
    0x0c2a.Rune,  0x0c33.Rune,  #  -
    0x0c35.Rune,  0x0c39.Rune,  #  -
    0x0c60.Rune,  0x0c61.Rune,  #  -
    0x0c85.Rune,  0x0c8c.Rune,  #  -
    0x0c8e.Rune,  0x0c90.Rune,  #  -
    0x0c92.Rune,  0x0ca8.Rune,  #  -
    0x0caa.Rune,  0x0cb3.Rune,  #  -
    0x0cb5.Rune,  0x0cb9.Rune,  #  -
    0x0ce0.Rune,  0x0ce1.Rune,  #  -
    0x0d05.Rune,  0x0d0c.Rune,  #  -
    0x0d0e.Rune,  0x0d10.Rune,  #  -
    0x0d12.Rune,  0x0d28.Rune,  #  -
    0x0d2a.Rune,  0x0d39.Rune,  #  -
    0x0d60.Rune,  0x0d61.Rune,  #  -
    0x0e01.Rune,  0x0e30.Rune,  #  -
    0x0e32.Rune,  0x0e33.Rune,  #  -
    0x0e40.Rune,  0x0e46.Rune,  #  -
    0x0e5a.Rune,  0x0e5b.Rune,  #  -
    0x0e81.Rune,  0x0e82.Rune,  #  -
    0x0e87.Rune,  0x0e88.Rune,  #  -
    0x0e94.Rune,  0x0e97.Rune,  #  -
    0x0e99.Rune,  0x0e9f.Rune,  #  -
    0x0ea1.Rune,  0x0ea3.Rune,  #  -
    0x0eaa.Rune,  0x0eab.Rune,  #  -
    0x0ead.Rune,  0x0eae.Rune,  #  -
    0x0eb2.Rune,  0x0eb3.Rune,  #  -
    0x0ec0.Rune,  0x0ec4.Rune,  #  -
    0x0edc.Rune,  0x0edd.Rune,  #  -
    0x0f18.Rune,  0x0f19.Rune,  #  -
    0x0f40.Rune,  0x0f47.Rune,  #  -
    0x0f49.Rune,  0x0f69.Rune,  #  -
    0x10d0.Rune,  0x10f6.Rune,  #  -
    0x1100.Rune,  0x1159.Rune,  #  -
    0x115f.Rune,  0x11a2.Rune,  #  -
    0x11a8.Rune,  0x11f9.Rune,  #  -
    0x1e00.Rune,  0x1e9b.Rune,  #  -
    0x1f50.Rune,  0x1f57.Rune,  #  -
    0x1f80.Rune,  0x1fb4.Rune,  #  -
    0x1fb6.Rune,  0x1fbc.Rune,  #  -
    0x1fc2.Rune,  0x1fc4.Rune,  #  -
    0x1fc6.Rune,  0x1fcc.Rune,  #  -
    0x1fd0.Rune,  0x1fd3.Rune,  #  -
    0x1fd6.Rune,  0x1fdb.Rune,  #  -
    0x1fe0.Rune,  0x1fec.Rune,  #  -
    0x1ff2.Rune,  0x1ff4.Rune,  #  -
    0x1ff6.Rune,  0x1ffc.Rune,  #  -
    0x210a.Rune,  0x2113.Rune,  #  -
    0x2115.Rune,  0x211d.Rune,  #  -
    0x2120.Rune,  0x2122.Rune,  #  -
    0x212a.Rune,  0x2131.Rune,  #  -
    0x2133.Rune,  0x2138.Rune,  #  -
    0x3041.Rune,  0x3094.Rune,  #  -
    0x30a1.Rune,  0x30fa.Rune,  #  -
    0x3105.Rune,  0x312c.Rune,  #  -
    0x3131.Rune,  0x318e.Rune,  #  -
    0x3192.Rune,  0x319f.Rune,  #  -
    0x3260.Rune,  0x327b.Rune,  #  -
    0x328a.Rune,  0x32b0.Rune,  #  -
    0x32d0.Rune,  0x32fe.Rune,  #  -
    0x3300.Rune,  0x3357.Rune,  #  -
    0x3371.Rune,  0x3376.Rune,  #  -
    0x337b.Rune,  0x3394.Rune,  #  -
    0x3399.Rune,  0x339e.Rune,  #  -
    0x33a9.Rune,  0x33ad.Rune,  #  -
    0x33b0.Rune,  0x33c1.Rune,  #  -
    0x33c3.Rune,  0x33c5.Rune,  #  -
    0x33c7.Rune,  0x33d7.Rune,  #  -
    0x33d9.Rune,  0x33dd.Rune,  #  -
    0x4e00.Rune,  0x9fff.Rune,  #  -
    0xac00.Rune,  0xd7a3.Rune,  #  -
    0xf900.Rune,  0xfb06.Rune,  #  -
    0xfb13.Rune,  0xfb17.Rune,  #  -
    0xfb1f.Rune,  0xfb28.Rune,  #  -
    0xfb2a.Rune,  0xfb36.Rune,  #  -
    0xfb38.Rune,  0xfb3c.Rune,  #  -
    0xfb40.Rune,  0xfb41.Rune,  #  -
    0xfb43.Rune,  0xfb44.Rune,  #  -
    0xfb46.Rune,  0xfbb1.Rune,  #  -
    0xfbd3.Rune,  0xfd3d.Rune,  #  -
    0xfd50.Rune,  0xfd8f.Rune,  #  -
    0xfd92.Rune,  0xfdc7.Rune,  #  -
    0xfdf0.Rune,  0xfdf9.Rune,  #  -
    0xfe70.Rune,  0xfe72.Rune,  #  -
    0xfe76.Rune,  0xfefc.Rune,  #  -
    0xff66.Rune,  0xff6f.Rune,  #  -
    0xff71.Rune,  0xff9d.Rune,  #  -
    0xffa0.Rune,  0xffbe.Rune,  #  -
    0xffc2.Rune,  0xffc7.Rune,  #  -
    0xffca.Rune,  0xffcf.Rune,  #  -
    0xffd2.Rune,  0xffd7.Rune,  #  -
    0xffda.Rune,  0xffdc.Rune]  #  -

  alphaSinglets = [
    0x00aa.Rune,  #
    0x00b5.Rune,  #
    0x00ba.Rune,  #
    0x03da.Rune,  #
    0x03dc.Rune,  #
    0x03de.Rune,  #
    0x03e0.Rune,  #
    0x06d5.Rune,  #
    0x09b2.Rune,  #
    0x0a5e.Rune,  #
    0x0a8d.Rune,  #
    0x0ae0.Rune,  #
    0x0b9c.Rune,  #
    0x0cde.Rune,  #
    0x0e4f.Rune,  #
    0x0e84.Rune,  #
    0x0e8a.Rune,  #
    0x0e8d.Rune,  #
    0x0ea5.Rune,  #
    0x0ea7.Rune,  #
    0x0eb0.Rune,  #
    0x0ebd.Rune,  #
    0x1fbe.Rune,  #
    0x207f.Rune,  #
    0x20a8.Rune,  #
    0x2102.Rune,  #
    0x2107.Rune,  #
    0x2124.Rune,  #
    0x2126.Rune,  #
    0x2128.Rune,  #
    0xfb3e.Rune,  #
    0xfe74.Rune]  #

  spaceRanges = [
    0x0009.Rune,  0x000d.Rune,  # tab and newline
    0x0020.Rune,  0x0020.Rune,  # space
    0x0085.Rune,  0x0085.Rune,  # next line
    0x00a0.Rune,  0x00a0.Rune,  #
    0x1680.Rune,  0x1680.Rune,  # Ogham space mark
    0x2000.Rune,  0x200b.Rune,  # en dash .. zero-width space
    0x200e.Rune,  0x200f.Rune,  # LTR mark .. RTL mark (pattern whitespace)
    0x2028.Rune,  0x2029.Rune,  #  -     0x3000.Rune,  0x3000.Rune,  #
    0x202f.Rune,  0x202f.Rune,  # narrow no-break space
    0x205f.Rune,  0x205f.Rune,  # medium mathematical space
    0x3000.Rune,  0x3000.Rune,  # ideographic space
    0xfeff.Rune,  0xfeff.Rune]  #

  toupperRanges = [
    0x0061.Rune,  0x007a.Rune, 468.Rune,  # a-z A-Z
    0x00e0.Rune,  0x00f6.Rune, 468.Rune,  # - -
    0x00f8.Rune,  0x00fe.Rune, 468.Rune,  # - -
    0x0256.Rune,  0x0257.Rune, 295.Rune,  # - -
    0x0258.Rune,  0x0259.Rune, 298.Rune,  # - -
    0x028a.Rune,  0x028b.Rune, 283.Rune,  # - -
    0x03ad.Rune,  0x03af.Rune, 463.Rune,  # - -
    0x03b1.Rune,  0x03c1.Rune, 468.Rune,  # - -
    0x03c3.Rune,  0x03cb.Rune, 468.Rune,  # - -
    0x03cd.Rune,  0x03ce.Rune, 437.Rune,  # - -
    0x0430.Rune,  0x044f.Rune, 468.Rune,  # - -
    0x0451.Rune,  0x045c.Rune, 420.Rune,  # - -
    0x045e.Rune,  0x045f.Rune, 420.Rune,  # - -
    0x0561.Rune,  0x0586.Rune, 452.Rune,  # - -
    0x1f00.Rune,  0x1f07.Rune, 508.Rune,  # - -
    0x1f10.Rune,  0x1f15.Rune, 508.Rune,  # - -
    0x1f20.Rune,  0x1f27.Rune, 508.Rune,  # - -
    0x1f30.Rune,  0x1f37.Rune, 508.Rune,  # - -
    0x1f40.Rune,  0x1f45.Rune, 508.Rune,  # - -
    0x1f60.Rune,  0x1f67.Rune, 508.Rune,  # - -
    0x1f70.Rune,  0x1f71.Rune, 574.Rune,  # - -
    0x1f72.Rune,  0x1f75.Rune, 586.Rune,  # - -
    0x1f76.Rune,  0x1f77.Rune, 600.Rune,  # - -
    0x1f78.Rune,  0x1f79.Rune, 628.Rune,  # - -
    0x1f7a.Rune,  0x1f7b.Rune, 612.Rune,  # - -
    0x1f7c.Rune,  0x1f7d.Rune, 626.Rune,  # - -
    0x1f80.Rune,  0x1f87.Rune, 508.Rune,  # - -
    0x1f90.Rune,  0x1f97.Rune, 508.Rune,  # - -
    0x1fa0.Rune,  0x1fa7.Rune, 508.Rune,  # - -
    0x1fb0.Rune,  0x1fb1.Rune, 508.Rune,  # - -
    0x1fd0.Rune,  0x1fd1.Rune, 508.Rune,  # - -
    0x1fe0.Rune,  0x1fe1.Rune, 508.Rune,  # - -
    0x2170.Rune,  0x217f.Rune, 484.Rune,  # - -
    0x24d0.Rune,  0x24e9.Rune, 474.Rune,  # - -
    0xff41.Rune,  0xff5a.Rune, 468.Rune]  # - -

  toupperSinglets = [
    0x00ff.Rune, 621.Rune,  #
    0x0101.Rune, 499.Rune,  #
    0x0103.Rune, 499.Rune,  #
    0x0105.Rune, 499.Rune,  #
    0x0107.Rune, 499.Rune,  #
    0x0109.Rune, 499.Rune,  #
    0x010b.Rune, 499.Rune,  #
    0x010d.Rune, 499.Rune,  #
    0x010f.Rune, 499.Rune,  #
    0x0111.Rune, 499.Rune,  #
    0x0113.Rune, 499.Rune,  #
    0x0115.Rune, 499.Rune,  #
    0x0117.Rune, 499.Rune,  #
    0x0119.Rune, 499.Rune,  #
    0x011b.Rune, 499.Rune,  #
    0x011d.Rune, 499.Rune,  #
    0x011f.Rune, 499.Rune,  #
    0x0121.Rune, 499.Rune,  #
    0x0123.Rune, 499.Rune,  #
    0x0125.Rune, 499.Rune,  #
    0x0127.Rune, 499.Rune,  #
    0x0129.Rune, 499.Rune,  #
    0x012b.Rune, 499.Rune,  #
    0x012d.Rune, 499.Rune,  #
    0x012f.Rune, 499.Rune,  #
    0x0131.Rune, 268.Rune,  #  I
    0x0133.Rune, 499.Rune,  #
    0x0135.Rune, 499.Rune,  #
    0x0137.Rune, 499.Rune,  #
    0x013a.Rune, 499.Rune,  #
    0x013c.Rune, 499.Rune,  #
    0x013e.Rune, 499.Rune,  #
    0x0140.Rune, 499.Rune,  #
    0x0142.Rune, 499.Rune,  #
    0x0144.Rune, 499.Rune,  #
    0x0146.Rune, 499.Rune,  #
    0x0148.Rune, 499.Rune,  #
    0x014b.Rune, 499.Rune,  #
    0x014d.Rune, 499.Rune,  #
    0x014f.Rune, 499.Rune,  #
    0x0151.Rune, 499.Rune,  #
    0x0153.Rune, 499.Rune,  #
    0x0155.Rune, 499.Rune,  #
    0x0157.Rune, 499.Rune,  #
    0x0159.Rune, 499.Rune,  #
    0x015b.Rune, 499.Rune,  #
    0x015d.Rune, 499.Rune,  #
    0x015f.Rune, 499.Rune,  #
    0x0161.Rune, 499.Rune,  #
    0x0163.Rune, 499.Rune,  #
    0x0165.Rune, 499.Rune,  #
    0x0167.Rune, 499.Rune,  #
    0x0169.Rune, 499.Rune,  #
    0x016b.Rune, 499.Rune,  #
    0x016d.Rune, 499.Rune,  #
    0x016f.Rune, 499.Rune,  #
    0x0171.Rune, 499.Rune,  #
    0x0173.Rune, 499.Rune,  #
    0x0175.Rune, 499.Rune,  #
    0x0177.Rune, 499.Rune,  #
    0x017a.Rune, 499.Rune,  #
    0x017c.Rune, 499.Rune,  #
    0x017e.Rune, 499.Rune,  #
    0x017f.Rune, 200.Rune,  #  S
    0x0183.Rune, 499.Rune,  #
    0x0185.Rune, 499.Rune,  #
    0x0188.Rune, 499.Rune,  #
    0x018c.Rune, 499.Rune,  #
    0x0192.Rune, 499.Rune,  #
    0x0199.Rune, 499.Rune,  #
    0x01a1.Rune, 499.Rune,  #
    0x01a3.Rune, 499.Rune,  #
    0x01a5.Rune, 499.Rune,  #
    0x01a8.Rune, 499.Rune,  #
    0x01ad.Rune, 499.Rune,  #
    0x01b0.Rune, 499.Rune,  #
    0x01b4.Rune, 499.Rune,  #
    0x01b6.Rune, 499.Rune,  #
    0x01b9.Rune, 499.Rune,  #
    0x01bd.Rune, 499.Rune,  #
    0x01c5.Rune, 499.Rune,  #
    0x01c6.Rune, 498.Rune,  #
    0x01c8.Rune, 499.Rune,  #
    0x01c9.Rune, 498.Rune,  #
    0x01cb.Rune, 499.Rune,  #
    0x01cc.Rune, 498.Rune,  #
    0x01ce.Rune, 499.Rune,  #
    0x01d0.Rune, 499.Rune,  #
    0x01d2.Rune, 499.Rune,  #
    0x01d4.Rune, 499.Rune,  #
    0x01d6.Rune, 499.Rune,  #
    0x01d8.Rune, 499.Rune,  #
    0x01da.Rune, 499.Rune,  #
    0x01dc.Rune, 499.Rune,  #
    0x01df.Rune, 499.Rune,  #
    0x01e1.Rune, 499.Rune,  #
    0x01e3.Rune, 499.Rune,  #
    0x01e5.Rune, 499.Rune,  #
    0x01e7.Rune, 499.Rune,  #
    0x01e9.Rune, 499.Rune,  #
    0x01eb.Rune, 499.Rune,  #
    0x01ed.Rune, 499.Rune,  #
    0x01ef.Rune, 499.Rune,  #
    0x01f2.Rune, 499.Rune,  #
    0x01f3.Rune, 498.Rune,  #
    0x01f5.Rune, 499.Rune,  #
    0x01fb.Rune, 499.Rune,  #
    0x01fd.Rune, 499.Rune,  #
    0x01ff.Rune, 499.Rune,  #
    0x0201.Rune, 499.Rune,  #
    0x0203.Rune, 499.Rune,  #
    0x0205.Rune, 499.Rune,  #
    0x0207.Rune, 499.Rune,  #
    0x0209.Rune, 499.Rune,  #
    0x020b.Rune, 499.Rune,  #
    0x020d.Rune, 499.Rune,  #
    0x020f.Rune, 499.Rune,  #
    0x0211.Rune, 499.Rune,  #
    0x0213.Rune, 499.Rune,  #
    0x0215.Rune, 499.Rune,  #
    0x0217.Rune, 499.Rune,  #
    0x0253.Rune, 290.Rune,  #
    0x0254.Rune, 294.Rune,  #
    0x025b.Rune, 297.Rune,  #
    0x0260.Rune, 295.Rune,  #
    0x0263.Rune, 293.Rune,  #
    0x0268.Rune, 291.Rune,  #
    0x0269.Rune, 289.Rune,  #
    0x026f.Rune, 289.Rune,  #
    0x0272.Rune, 287.Rune,  #
    0x0283.Rune, 282.Rune,  #
    0x0288.Rune, 282.Rune,  #
    0x0292.Rune, 281.Rune,  #
    0x03ac.Rune, 462.Rune,  #
    0x03cc.Rune, 436.Rune,  #
    0x03d0.Rune, 438.Rune,  #
    0x03d1.Rune, 443.Rune,  #
    0x03d5.Rune, 453.Rune,  #
    0x03d6.Rune, 446.Rune,  #
    0x03e3.Rune, 499.Rune,  #
    0x03e5.Rune, 499.Rune,  #
    0x03e7.Rune, 499.Rune,  #
    0x03e9.Rune, 499.Rune,  #
    0x03eb.Rune, 499.Rune,  #
    0x03ed.Rune, 499.Rune,  #
    0x03ef.Rune, 499.Rune,  #
    0x03f0.Rune, 414.Rune,  #
    0x03f1.Rune, 420.Rune,  #
    0x0461.Rune, 499.Rune,  #
    0x0463.Rune, 499.Rune,  #
    0x0465.Rune, 499.Rune,  #
    0x0467.Rune, 499.Rune,  #
    0x0469.Rune, 499.Rune,  #
    0x046b.Rune, 499.Rune,  #
    0x046d.Rune, 499.Rune,  #
    0x046f.Rune, 499.Rune,  #
    0x0471.Rune, 499.Rune,  #
    0x0473.Rune, 499.Rune,  #
    0x0475.Rune, 499.Rune,  #
    0x0477.Rune, 499.Rune,  #
    0x0479.Rune, 499.Rune,  #
    0x047b.Rune, 499.Rune,  #
    0x047d.Rune, 499.Rune,  #
    0x047f.Rune, 499.Rune,  #
    0x0481.Rune, 499.Rune,  #
    0x0491.Rune, 499.Rune,  #
    0x0493.Rune, 499.Rune,  #
    0x0495.Rune, 499.Rune,  #
    0x0497.Rune, 499.Rune,  #
    0x0499.Rune, 499.Rune,  #
    0x049b.Rune, 499.Rune,  #
    0x049d.Rune, 499.Rune,  #
    0x049f.Rune, 499.Rune,  #
    0x04a1.Rune, 499.Rune,  #
    0x04a3.Rune, 499.Rune,  #
    0x04a5.Rune, 499.Rune,  #
    0x04a7.Rune, 499.Rune,  #
    0x04a9.Rune, 499.Rune,  #
    0x04ab.Rune, 499.Rune,  #
    0x04ad.Rune, 499.Rune,  #
    0x04af.Rune, 499.Rune,  #
    0x04b1.Rune, 499.Rune,  #
    0x04b3.Rune, 499.Rune,  #
    0x04b5.Rune, 499.Rune,  #
    0x04b7.Rune, 499.Rune,  #
    0x04b9.Rune, 499.Rune,  #
    0x04bb.Rune, 499.Rune,  #
    0x04bd.Rune, 499.Rune,  #
    0x04bf.Rune, 499.Rune,  #
    0x04c2.Rune, 499.Rune,  #
    0x04c4.Rune, 499.Rune,  #
    0x04c8.Rune, 499.Rune,  #
    0x04cc.Rune, 499.Rune,  #
    0x04d1.Rune, 499.Rune,  #
    0x04d3.Rune, 499.Rune,  #
    0x04d5.Rune, 499.Rune,  #
    0x04d7.Rune, 499.Rune,  #
    0x04d9.Rune, 499.Rune,  #
    0x04db.Rune, 499.Rune,  #
    0x04dd.Rune, 499.Rune,  #
    0x04df.Rune, 499.Rune,  #
    0x04e1.Rune, 499.Rune,  #
    0x04e3.Rune, 499.Rune,  #
    0x04e5.Rune, 499.Rune,  #
    0x04e7.Rune, 499.Rune,  #
    0x04e9.Rune, 499.Rune,  #
    0x04eb.Rune, 499.Rune,  #
    0x04ef.Rune, 499.Rune,  #
    0x04f1.Rune, 499.Rune,  #
    0x04f3.Rune, 499.Rune,  #
    0x04f5.Rune, 499.Rune,  #
    0x04f9.Rune, 499.Rune,  #
    0x1e01.Rune, 499.Rune,  #
    0x1e03.Rune, 499.Rune,  #
    0x1e05.Rune, 499.Rune,  #
    0x1e07.Rune, 499.Rune,  #
    0x1e09.Rune, 499.Rune,  #
    0x1e0b.Rune, 499.Rune,  #
    0x1e0d.Rune, 499.Rune,  #
    0x1e0f.Rune, 499.Rune,  #
    0x1e11.Rune, 499.Rune,  #
    0x1e13.Rune, 499.Rune,  #
    0x1e15.Rune, 499.Rune,  #
    0x1e17.Rune, 499.Rune,  #
    0x1e19.Rune, 499.Rune,  #
    0x1e1b.Rune, 499.Rune,  #
    0x1e1d.Rune, 499.Rune,  #
    0x1e1f.Rune, 499.Rune,  #
    0x1e21.Rune, 499.Rune,  #
    0x1e23.Rune, 499.Rune,  #
    0x1e25.Rune, 499.Rune,  #
    0x1e27.Rune, 499.Rune,  #
    0x1e29.Rune, 499.Rune,  #
    0x1e2b.Rune, 499.Rune,  #
    0x1e2d.Rune, 499.Rune,  #
    0x1e2f.Rune, 499.Rune,  #
    0x1e31.Rune, 499.Rune,  #
    0x1e33.Rune, 499.Rune,  #
    0x1e35.Rune, 499.Rune,  #
    0x1e37.Rune, 499.Rune,  #
    0x1e39.Rune, 499.Rune,  #
    0x1e3b.Rune, 499.Rune,  #
    0x1e3d.Rune, 499.Rune,  #
    0x1e3f.Rune, 499.Rune,  #
    0x1e41.Rune, 499.Rune,  #
    0x1e43.Rune, 499.Rune,  #
    0x1e45.Rune, 499.Rune,  #
    0x1e47.Rune, 499.Rune,  #
    0x1e49.Rune, 499.Rune,  #
    0x1e4b.Rune, 499.Rune,  #
    0x1e4d.Rune, 499.Rune,  #
    0x1e4f.Rune, 499.Rune,  #
    0x1e51.Rune, 499.Rune,  #
    0x1e53.Rune, 499.Rune,  #
    0x1e55.Rune, 499.Rune,  #
    0x1e57.Rune, 499.Rune,  #
    0x1e59.Rune, 499.Rune,  #
    0x1e5b.Rune, 499.Rune,  #
    0x1e5d.Rune, 499.Rune,  #
    0x1e5f.Rune, 499.Rune,  #
    0x1e61.Rune, 499.Rune,  #
    0x1e63.Rune, 499.Rune,  #
    0x1e65.Rune, 499.Rune,  #
    0x1e67.Rune, 499.Rune,  #
    0x1e69.Rune, 499.Rune,  #
    0x1e6b.Rune, 499.Rune,  #
    0x1e6d.Rune, 499.Rune,  #
    0x1e6f.Rune, 499.Rune,  #
    0x1e71.Rune, 499.Rune,  #
    0x1e73.Rune, 499.Rune,  #
    0x1e75.Rune, 499.Rune,  #
    0x1e77.Rune, 499.Rune,  #
    0x1e79.Rune, 499.Rune,  #
    0x1e7b.Rune, 499.Rune,  #
    0x1e7d.Rune, 499.Rune,  #
    0x1e7f.Rune, 499.Rune,  #
    0x1e81.Rune, 499.Rune,  #
    0x1e83.Rune, 499.Rune,  #
    0x1e85.Rune, 499.Rune,  #
    0x1e87.Rune, 499.Rune,  #
    0x1e89.Rune, 499.Rune,  #
    0x1e8b.Rune, 499.Rune,  #
    0x1e8d.Rune, 499.Rune,  #
    0x1e8f.Rune, 499.Rune,  #
    0x1e91.Rune, 499.Rune,  #
    0x1e93.Rune, 499.Rune,  #
    0x1e95.Rune, 499.Rune,  #
    0x1ea1.Rune, 499.Rune,  #
    0x1ea3.Rune, 499.Rune,  #
    0x1ea5.Rune, 499.Rune,  #
    0x1ea7.Rune, 499.Rune,  #
    0x1ea9.Rune, 499.Rune,  #
    0x1eab.Rune, 499.Rune,  #
    0x1ead.Rune, 499.Rune,  #
    0x1eaf.Rune, 499.Rune,  #
    0x1eb1.Rune, 499.Rune,  #
    0x1eb3.Rune, 499.Rune,  #
    0x1eb5.Rune, 499.Rune,  #
    0x1eb7.Rune, 499.Rune,  #
    0x1eb9.Rune, 499.Rune,  #
    0x1ebb.Rune, 499.Rune,  #
    0x1ebd.Rune, 499.Rune,  #
    0x1ebf.Rune, 499.Rune,  #
    0x1ec1.Rune, 499.Rune,  #
    0x1ec3.Rune, 499.Rune,  #
    0x1ec5.Rune, 499.Rune,  #
    0x1ec7.Rune, 499.Rune,  #
    0x1ec9.Rune, 499.Rune,  #
    0x1ecb.Rune, 499.Rune,  #
    0x1ecd.Rune, 499.Rune,  #
    0x1ecf.Rune, 499.Rune,  #
    0x1ed1.Rune, 499.Rune,  #
    0x1ed3.Rune, 499.Rune,  #
    0x1ed5.Rune, 499.Rune,  #
    0x1ed7.Rune, 499.Rune,  #
    0x1ed9.Rune, 499.Rune,  #
    0x1edb.Rune, 499.Rune,  #
    0x1edd.Rune, 499.Rune,  #
    0x1edf.Rune, 499.Rune,  #
    0x1ee1.Rune, 499.Rune,  #
    0x1ee3.Rune, 499.Rune,  #
    0x1ee5.Rune, 499.Rune,  #
    0x1ee7.Rune, 499.Rune,  #
    0x1ee9.Rune, 499.Rune,  #
    0x1eeb.Rune, 499.Rune,  #
    0x1eed.Rune, 499.Rune,  #
    0x1eef.Rune, 499.Rune,  #
    0x1ef1.Rune, 499.Rune,  #
    0x1ef3.Rune, 499.Rune,  #
    0x1ef5.Rune, 499.Rune,  #
    0x1ef7.Rune, 499.Rune,  #
    0x1ef9.Rune, 499.Rune,  #
    0x1f51.Rune, 508.Rune,  #
    0x1f53.Rune, 508.Rune,  #
    0x1f55.Rune, 508.Rune,  #
    0x1f57.Rune, 508.Rune,  #
    0x1fb3.Rune, 509.Rune,  #
    0x1fc3.Rune, 509.Rune,  #
    0x1fe5.Rune, 507.Rune,  #
    0x1ff3.Rune, 509.Rune]  #

  tolowerRanges = [
    0x0041.Rune,  0x005a.Rune, 532.Rune,  # A-Z a-z
    0x00c0.Rune,  0x00d6.Rune, 532.Rune,  # - -
    0x00d8.Rune,  0x00de.Rune, 532.Rune,  # - -
    0x0189.Rune,  0x018a.Rune, 705.Rune,  # - -
    0x018e.Rune,  0x018f.Rune, 702.Rune,  # - -
    0x01b1.Rune,  0x01b2.Rune, 717.Rune,  # - -
    0x0388.Rune,  0x038a.Rune, 537.Rune,  # - -
    0x038e.Rune,  0x038f.Rune, 563.Rune,  # - -
    0x0391.Rune,  0x03a1.Rune, 532.Rune,  # - -
    0x03a3.Rune,  0x03ab.Rune, 532.Rune,  # - -
    0x0401.Rune,  0x040c.Rune, 580.Rune,  # - -
    0x040e.Rune,  0x040f.Rune, 580.Rune,  # - -
    0x0410.Rune,  0x042f.Rune, 532.Rune,  # - -
    0x0531.Rune,  0x0556.Rune, 548.Rune,  # - -
    0x10a0.Rune,  0x10c5.Rune, 548.Rune,  # - -
    0x1f08.Rune,  0x1f0f.Rune, 492.Rune,  # - -
    0x1f18.Rune,  0x1f1d.Rune, 492.Rune,  # - -
    0x1f28.Rune,  0x1f2f.Rune, 492.Rune,  # - -
    0x1f38.Rune,  0x1f3f.Rune, 492.Rune,  # - -
    0x1f48.Rune,  0x1f4d.Rune, 492.Rune,  # - -
    0x1f68.Rune,  0x1f6f.Rune, 492.Rune,  # - -
    0x1f88.Rune,  0x1f8f.Rune, 492.Rune,  # - -
    0x1f98.Rune,  0x1f9f.Rune, 492.Rune,  # - -
    0x1fa8.Rune,  0x1faf.Rune, 492.Rune,  # - -
    0x1fb8.Rune,  0x1fb9.Rune, 492.Rune,  # - -
    0x1fba.Rune,  0x1fbb.Rune, 426.Rune,  # - -
    0x1fc8.Rune,  0x1fcb.Rune, 414.Rune,  # - -
    0x1fd8.Rune,  0x1fd9.Rune, 492.Rune,  # - -
    0x1fda.Rune,  0x1fdb.Rune, 400.Rune,  # - -
    0x1fe8.Rune,  0x1fe9.Rune, 492.Rune,  # - -
    0x1fea.Rune,  0x1feb.Rune, 388.Rune,  # - -
    0x1ff8.Rune,  0x1ff9.Rune, 372.Rune,  # - -
    0x1ffa.Rune,  0x1ffb.Rune, 374.Rune,  # - -
    0x2160.Rune,  0x216f.Rune, 516.Rune,  # - -
    0x24b6.Rune,  0x24cf.Rune, 526.Rune,  # - -
    0xff21.Rune,  0xff3a.Rune, 532.Rune]  # - -

  tolowerSinglets = [
    0x0100.Rune, 501.Rune,  #
    0x0102.Rune, 501.Rune,  #
    0x0104.Rune, 501.Rune,  #
    0x0106.Rune, 501.Rune,  #
    0x0108.Rune, 501.Rune,  #
    0x010a.Rune, 501.Rune,  #
    0x010c.Rune, 501.Rune,  #
    0x010e.Rune, 501.Rune,  #
    0x0110.Rune, 501.Rune,  #
    0x0112.Rune, 501.Rune,  #
    0x0114.Rune, 501.Rune,  #
    0x0116.Rune, 501.Rune,  #
    0x0118.Rune, 501.Rune,  #
    0x011a.Rune, 501.Rune,  #
    0x011c.Rune, 501.Rune,  #
    0x011e.Rune, 501.Rune,  #
    0x0120.Rune, 501.Rune,  #
    0x0122.Rune, 501.Rune,  #
    0x0124.Rune, 501.Rune,  #
    0x0126.Rune, 501.Rune,  #
    0x0128.Rune, 501.Rune,  #
    0x012a.Rune, 501.Rune,  #
    0x012c.Rune, 501.Rune,  #
    0x012e.Rune, 501.Rune,  #
    0x0130.Rune, 301.Rune,  #  i
    0x0132.Rune, 501.Rune,  #
    0x0134.Rune, 501.Rune,  #
    0x0136.Rune, 501.Rune,  #
    0x0139.Rune, 501.Rune,  #
    0x013b.Rune, 501.Rune,  #
    0x013d.Rune, 501.Rune,  #
    0x013f.Rune, 501.Rune,  #
    0x0141.Rune, 501.Rune,  #
    0x0143.Rune, 501.Rune,  #
    0x0145.Rune, 501.Rune,  #
    0x0147.Rune, 501.Rune,  #
    0x014a.Rune, 501.Rune,  #
    0x014c.Rune, 501.Rune,  #
    0x014e.Rune, 501.Rune,  #
    0x0150.Rune, 501.Rune,  #
    0x0152.Rune, 501.Rune,  #
    0x0154.Rune, 501.Rune,  #
    0x0156.Rune, 501.Rune,  #
    0x0158.Rune, 501.Rune,  #
    0x015a.Rune, 501.Rune,  #
    0x015c.Rune, 501.Rune,  #
    0x015e.Rune, 501.Rune,  #
    0x0160.Rune, 501.Rune,  #
    0x0162.Rune, 501.Rune,  #
    0x0164.Rune, 501.Rune,  #
    0x0166.Rune, 501.Rune,  #
    0x0168.Rune, 501.Rune,  #
    0x016a.Rune, 501.Rune,  #
    0x016c.Rune, 501.Rune,  #
    0x016e.Rune, 501.Rune,  #
    0x0170.Rune, 501.Rune,  #
    0x0172.Rune, 501.Rune,  #
    0x0174.Rune, 501.Rune,  #
    0x0176.Rune, 501.Rune,  #
    0x0178.Rune, 379.Rune,  #
    0x0179.Rune, 501.Rune,  #
    0x017b.Rune, 501.Rune,  #
    0x017d.Rune, 501.Rune,  #
    0x0181.Rune, 710.Rune,  #
    0x0182.Rune, 501.Rune,  #
    0x0184.Rune, 501.Rune,  #
    0x0186.Rune, 706.Rune,  #
    0x0187.Rune, 501.Rune,  #
    0x018b.Rune, 501.Rune,  #
    0x0190.Rune, 703.Rune,  #
    0x0191.Rune, 501.Rune,  #
    0x0193.Rune, 705.Rune,  #
    0x0194.Rune, 707.Rune,  #
    0x0196.Rune, 711.Rune,  #
    0x0197.Rune, 709.Rune,  #
    0x0198.Rune, 501.Rune,  #
    0x019c.Rune, 711.Rune,  #
    0x019d.Rune, 713.Rune,  #
    0x01a0.Rune, 501.Rune,  #
    0x01a2.Rune, 501.Rune,  #
    0x01a4.Rune, 501.Rune,  #
    0x01a7.Rune, 501.Rune,  #
    0x01a9.Rune, 718.Rune,  #
    0x01ac.Rune, 501.Rune,  #
    0x01ae.Rune, 718.Rune,  #
    0x01af.Rune, 501.Rune,  #
    0x01b3.Rune, 501.Rune,  #
    0x01b5.Rune, 501.Rune,  #
    0x01b7.Rune, 719.Rune,  #
    0x01b8.Rune, 501.Rune,  #
    0x01bc.Rune, 501.Rune,  #
    0x01c4.Rune, 502.Rune,  #
    0x01c5.Rune, 501.Rune,  #
    0x01c7.Rune, 502.Rune,  #
    0x01c8.Rune, 501.Rune,  #
    0x01ca.Rune, 502.Rune,  #
    0x01cb.Rune, 501.Rune,  #
    0x01cd.Rune, 501.Rune,  #
    0x01cf.Rune, 501.Rune,  #
    0x01d1.Rune, 501.Rune,  #
    0x01d3.Rune, 501.Rune,  #
    0x01d5.Rune, 501.Rune,  #
    0x01d7.Rune, 501.Rune,  #
    0x01d9.Rune, 501.Rune,  #
    0x01db.Rune, 501.Rune,  #
    0x01de.Rune, 501.Rune,  #
    0x01e0.Rune, 501.Rune,  #
    0x01e2.Rune, 501.Rune,  #
    0x01e4.Rune, 501.Rune,  #
    0x01e6.Rune, 501.Rune,  #
    0x01e8.Rune, 501.Rune,  #
    0x01ea.Rune, 501.Rune,  #
    0x01ec.Rune, 501.Rune,  #
    0x01ee.Rune, 501.Rune,  #
    0x01f1.Rune, 502.Rune,  #
    0x01f2.Rune, 501.Rune,  #
    0x01f4.Rune, 501.Rune,  #
    0x01fa.Rune, 501.Rune,  #
    0x01fc.Rune, 501.Rune,  #
    0x01fe.Rune, 501.Rune,  #
    0x0200.Rune, 501.Rune,  #
    0x0202.Rune, 501.Rune,  #
    0x0204.Rune, 501.Rune,  #
    0x0206.Rune, 501.Rune,  #
    0x0208.Rune, 501.Rune,  #
    0x020a.Rune, 501.Rune,  #
    0x020c.Rune, 501.Rune,  #
    0x020e.Rune, 501.Rune,  #
    0x0210.Rune, 501.Rune,  #
    0x0212.Rune, 501.Rune,  #
    0x0214.Rune, 501.Rune,  #
    0x0216.Rune, 501.Rune,  #
    0x0386.Rune, 538.Rune,  #
    0x038c.Rune, 564.Rune,  #
    0x03e2.Rune, 501.Rune,  #
    0x03e4.Rune, 501.Rune,  #
    0x03e6.Rune, 501.Rune,  #
    0x03e8.Rune, 501.Rune,  #
    0x03ea.Rune, 501.Rune,  #
    0x03ec.Rune, 501.Rune,  #
    0x03ee.Rune, 501.Rune,  #
    0x0460.Rune, 501.Rune,  #
    0x0462.Rune, 501.Rune,  #
    0x0464.Rune, 501.Rune,  #
    0x0466.Rune, 501.Rune,  #
    0x0468.Rune, 501.Rune,  #
    0x046a.Rune, 501.Rune,  #
    0x046c.Rune, 501.Rune,  #
    0x046e.Rune, 501.Rune,  #
    0x0470.Rune, 501.Rune,  #
    0x0472.Rune, 501.Rune,  #
    0x0474.Rune, 501.Rune,  #
    0x0476.Rune, 501.Rune,  #
    0x0478.Rune, 501.Rune,  #
    0x047a.Rune, 501.Rune,  #
    0x047c.Rune, 501.Rune,  #
    0x047e.Rune, 501.Rune,  #
    0x0480.Rune, 501.Rune,  #
    0x0490.Rune, 501.Rune,  #
    0x0492.Rune, 501.Rune,  #
    0x0494.Rune, 501.Rune,  #
    0x0496.Rune, 501.Rune,  #
    0x0498.Rune, 501.Rune,  #
    0x049a.Rune, 501.Rune,  #
    0x049c.Rune, 501.Rune,  #
    0x049e.Rune, 501.Rune,  #
    0x04a0.Rune, 501.Rune,  #
    0x04a2.Rune, 501.Rune,  #
    0x04a4.Rune, 501.Rune,  #
    0x04a6.Rune, 501.Rune,  #
    0x04a8.Rune, 501.Rune,  #
    0x04aa.Rune, 501.Rune,  #
    0x04ac.Rune, 501.Rune,  #
    0x04ae.Rune, 501.Rune,  #
    0x04b0.Rune, 501.Rune,  #
    0x04b2.Rune, 501.Rune,  #
    0x04b4.Rune, 501.Rune,  #
    0x04b6.Rune, 501.Rune,  #
    0x04b8.Rune, 501.Rune,  #
    0x04ba.Rune, 501.Rune,  #
    0x04bc.Rune, 501.Rune,  #
    0x04be.Rune, 501.Rune,  #
    0x04c1.Rune, 501.Rune,  #
    0x04c3.Rune, 501.Rune,  #
    0x04c7.Rune, 501.Rune,  #
    0x04cb.Rune, 501.Rune,  #
    0x04d0.Rune, 501.Rune,  #
    0x04d2.Rune, 501.Rune,  #
    0x04d4.Rune, 501.Rune,  #
    0x04d6.Rune, 501.Rune,  #
    0x04d8.Rune, 501.Rune,  #
    0x04da.Rune, 501.Rune,  #
    0x04dc.Rune, 501.Rune,  #
    0x04de.Rune, 501.Rune,  #
    0x04e0.Rune, 501.Rune,  #
    0x04e2.Rune, 501.Rune,  #
    0x04e4.Rune, 501.Rune,  #
    0x04e6.Rune, 501.Rune,  #
    0x04e8.Rune, 501.Rune,  #
    0x04ea.Rune, 501.Rune,  #
    0x04ee.Rune, 501.Rune,  #
    0x04f0.Rune, 501.Rune,  #
    0x04f2.Rune, 501.Rune,  #
    0x04f4.Rune, 501.Rune,  #
    0x04f8.Rune, 501.Rune,  #
    0x1e00.Rune, 501.Rune,  #
    0x1e02.Rune, 501.Rune,  #
    0x1e04.Rune, 501.Rune,  #
    0x1e06.Rune, 501.Rune,  #
    0x1e08.Rune, 501.Rune,  #
    0x1e0a.Rune, 501.Rune,  #
    0x1e0c.Rune, 501.Rune,  #
    0x1e0e.Rune, 501.Rune,  #
    0x1e10.Rune, 501.Rune,  #
    0x1e12.Rune, 501.Rune,  #
    0x1e14.Rune, 501.Rune,  #
    0x1e16.Rune, 501.Rune,  #
    0x1e18.Rune, 501.Rune,  #
    0x1e1a.Rune, 501.Rune,  #
    0x1e1c.Rune, 501.Rune,  #
    0x1e1e.Rune, 501.Rune,  #
    0x1e20.Rune, 501.Rune,  #
    0x1e22.Rune, 501.Rune,  #
    0x1e24.Rune, 501.Rune,  #
    0x1e26.Rune, 501.Rune,  #
    0x1e28.Rune, 501.Rune,  #
    0x1e2a.Rune, 501.Rune,  #
    0x1e2c.Rune, 501.Rune,  #
    0x1e2e.Rune, 501.Rune,  #
    0x1e30.Rune, 501.Rune,  #
    0x1e32.Rune, 501.Rune,  #
    0x1e34.Rune, 501.Rune,  #
    0x1e36.Rune, 501.Rune,  #
    0x1e38.Rune, 501.Rune,  #
    0x1e3a.Rune, 501.Rune,  #
    0x1e3c.Rune, 501.Rune,  #
    0x1e3e.Rune, 501.Rune,  #
    0x1e40.Rune, 501.Rune,  #
    0x1e42.Rune, 501.Rune,  #
    0x1e44.Rune, 501.Rune,  #
    0x1e46.Rune, 501.Rune,  #
    0x1e48.Rune, 501.Rune,  #
    0x1e4a.Rune, 501.Rune,  #
    0x1e4c.Rune, 501.Rune,  #
    0x1e4e.Rune, 501.Rune,  #
    0x1e50.Rune, 501.Rune,  #
    0x1e52.Rune, 501.Rune,  #
    0x1e54.Rune, 501.Rune,  #
    0x1e56.Rune, 501.Rune,  #
    0x1e58.Rune, 501.Rune,  #
    0x1e5a.Rune, 501.Rune,  #
    0x1e5c.Rune, 501.Rune,  #
    0x1e5e.Rune, 501.Rune,  #
    0x1e60.Rune, 501.Rune,  #
    0x1e62.Rune, 501.Rune,  #
    0x1e64.Rune, 501.Rune,  #
    0x1e66.Rune, 501.Rune,  #
    0x1e68.Rune, 501.Rune,  #
    0x1e6a.Rune, 501.Rune,  #
    0x1e6c.Rune, 501.Rune,  #
    0x1e6e.Rune, 501.Rune,  #
    0x1e70.Rune, 501.Rune,  #
    0x1e72.Rune, 501.Rune,  #
    0x1e74.Rune, 501.Rune,  #
    0x1e76.Rune, 501.Rune,  #
    0x1e78.Rune, 501.Rune,  #
    0x1e7a.Rune, 501.Rune,  #
    0x1e7c.Rune, 501.Rune,  #
    0x1e7e.Rune, 501.Rune,  #
    0x1e80.Rune, 501.Rune,  #
    0x1e82.Rune, 501.Rune,  #
    0x1e84.Rune, 501.Rune,  #
    0x1e86.Rune, 501.Rune,  #
    0x1e88.Rune, 501.Rune,  #
    0x1e8a.Rune, 501.Rune,  #
    0x1e8c.Rune, 501.Rune,  #
    0x1e8e.Rune, 501.Rune,  #
    0x1e90.Rune, 501.Rune,  #
    0x1e92.Rune, 501.Rune,  #
    0x1e94.Rune, 501.Rune,  #
    0x1ea0.Rune, 501.Rune,  #
    0x1ea2.Rune, 501.Rune,  #
    0x1ea4.Rune, 501.Rune,  #
    0x1ea6.Rune, 501.Rune,  #
    0x1ea8.Rune, 501.Rune,  #
    0x1eaa.Rune, 501.Rune,  #
    0x1eac.Rune, 501.Rune,  #
    0x1eae.Rune, 501.Rune,  #
    0x1eb0.Rune, 501.Rune,  #
    0x1eb2.Rune, 501.Rune,  #
    0x1eb4.Rune, 501.Rune,  #
    0x1eb6.Rune, 501.Rune,  #
    0x1eb8.Rune, 501.Rune,  #
    0x1eba.Rune, 501.Rune,  #
    0x1ebc.Rune, 501.Rune,  #
    0x1ebe.Rune, 501.Rune,  #
    0x1ec0.Rune, 501.Rune,  #
    0x1ec2.Rune, 501.Rune,  #
    0x1ec4.Rune, 501.Rune,  #
    0x1ec6.Rune, 501.Rune,  #
    0x1ec8.Rune, 501.Rune,  #
    0x1eca.Rune, 501.Rune,  #
    0x1ecc.Rune, 501.Rune,  #
    0x1ece.Rune, 501.Rune,  #
    0x1ed0.Rune, 501.Rune,  #
    0x1ed2.Rune, 501.Rune,  #
    0x1ed4.Rune, 501.Rune,  #
    0x1ed6.Rune, 501.Rune,  #
    0x1ed8.Rune, 501.Rune,  #
    0x1eda.Rune, 501.Rune,  #
    0x1edc.Rune, 501.Rune,  #
    0x1ede.Rune, 501.Rune,  #
    0x1ee0.Rune, 501.Rune,  #
    0x1ee2.Rune, 501.Rune,  #
    0x1ee4.Rune, 501.Rune,  #
    0x1ee6.Rune, 501.Rune,  #
    0x1ee8.Rune, 501.Rune,  #
    0x1eea.Rune, 501.Rune,  #
    0x1eec.Rune, 501.Rune,  #
    0x1eee.Rune, 501.Rune,  #
    0x1ef0.Rune, 501.Rune,  #
    0x1ef2.Rune, 501.Rune,  #
    0x1ef4.Rune, 501.Rune,  #
    0x1ef6.Rune, 501.Rune,  #
    0x1ef8.Rune, 501.Rune,  #
    0x1f59.Rune, 492.Rune,  #
    0x1f5b.Rune, 492.Rune,  #
    0x1f5d.Rune, 492.Rune,  #
    0x1f5f.Rune, 492.Rune,  #
    0x1fbc.Rune, 491.Rune,  #
    0x1fcc.Rune, 491.Rune,  #
    0x1fec.Rune, 493.Rune,  #
    0x1ffc.Rune, 491.Rune]  #

  toTitleSinglets = [
    0x01c4.Rune, 501.Rune,  #
    0x01c6.Rune, 499.Rune,  #
    0x01c7.Rune, 501.Rune,  #
    0x01c9.Rune, 499.Rune,  #
    0x01ca.Rune, 501.Rune,  #
    0x01cc.Rune, 499.Rune,  #
    0x01f1.Rune, 501.Rune,  #
    0x01f3.Rune, 499.Rune]  #

proc binarySearch(c: RuneImpl, tab: openArray[Rune], len, stride: int): int =
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
  if p >= 0 and c >= tolowerRanges[p] and c <= tolowerRanges[p + 1]:
    return Rune(c.int32 + tolowerRanges[p + 2].int32 - 500)
  p = binarySearch(c, tolowerSinglets, len(tolowerSinglets) div 2, 2)
  if p >= 0 and c == tolowerSinglets[p]:
    return Rune(c.int32 + tolowerSinglets[p + 1].int32 - 500)
  return Rune(c)

proc toUpper*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` into upper case. This works for any Unicode character.
  ## If possible, prefer ``toLower`` over ``toUpper``.
  var c = RuneImpl(c)
  var p = binarySearch(c, toupperRanges, len(toupperRanges) div 3, 3)
  if p >= 0 and c >= toupperRanges[p] and c <= toupperRanges[p + 1]:
    return Rune(c.int32 + toupperRanges[p + 2].int32 - 500)
  p = binarySearch(c, toupperSinglets, len(toupperSinglets) div 2, 2)
  if p >= 0 and c == toupperSinglets[p]:
    return Rune(c.int32 + toupperSinglets[p + 1].int32 - 500)
  return Rune(c)

proc toTitle*(c: Rune): Rune {.rtl, extern: "nuc$1", procvar.} =
  ## Converts ``c`` to title case
  var c = RuneImpl(c)
  var p = binarySearch(c, toTitleSinglets, len(toTitleSinglets) div 2, 2)
  if p >= 0 and c.int32 == toTitleSinglets[p].int32:
    return Rune(c.int32 + toTitleSinglets[p + 1].int32 - 500)
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
  ## Common code for rune.isLower, rune.isUpper, etc
  result = if len(s) == 0: false else: true

  var
    i = 0
    rune: Rune

  while i < len(s) and result:
    fastRuneAt(s, i, rune, doInc=true)
    result = runeProc(rune) and result

proc isUpper*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all upper case unicode characters.
  runeCheck(s, isUpper)

proc isLower*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all lower case unicode characters.
  runeCheck(s, isLower)

proc isAlpha*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all alphabetic unicode characters.
  runeCheck(s, isAlpha)

proc isSpace*(s: string): bool {.noSideEffect, procvar,
  rtl, extern: "nuc$1Str".} =
  ## Returns true iff `s` contains all whitespace unicode characters.
  runeCheck(s, isWhiteSpace)

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

proc normalizeUnicode*(s: string): string {.noSideEffect,
  rtl, extern: "nucNormalize".} =
  ## Normalizes the string ``s``.
  ##
  ## That means to convert it to lower case and remove any ``'_'``.
  const
    underscore = '_'.Rune
  var
    i = 0
    written = 0
    rune: Rune
  result = newString(len(s))
  while i < len(s):
    fastRuneAt(s, i, rune)
    if rune.isUpper():
      rune = rune.toLower()
    if rune != underscore:
      rune.fastToUTF8Copy(result, written)

proc strip*(s: string, leading = true, trailing = true,
  runes: openarray[Rune] = spaceRanges): string {.noSideEffect,
  rtl, extern: "nucStrip".} =
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

proc align*(s: string, count: Natural, padding: Rune = ' '.Rune): string {.
  noSideEffect, rtl, extern: "nucAlignString".} =
  ## Aligns a unicode string `s` with `padding`, so that it has a rune-length
  ## of `count`.
  ##
  ## `padding` characters (by default spaces) are added before `s` resulting in
  ## right alignment. If ``s.runelen >= count``, no spaces are added and `s` is
  ## returned unchanged. If you need to left align a string use the `alignLeft
  ## proc <#alignLeft>`_. Example:
  ##
  ## .. code-block:: nim
  ##   assert align("abc", 4) == " abc"
  ##   assert align("a", 0) == "a"
  ##   assert align("1232", 6) == "  1232"
  ##   assert align("1232", 6, '#') == "##1232"
  ##   assert align("Åge", 5) == "  Åge"
  ##   assert align("×", 4, '_'.Rune) == "___×"
  ##   assert align(" Hello", 9, "×".asRune) == "××× Hello"
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
  ## proc <#align>`_. Example:
  ##
  ## .. code-block:: nim
  ##   assert alignLeft("abc", 4) == "abc "
  ##   assert alignLeft("a", 0) == "a"
  ##   assert alignLeft("1232", 6) == "1232  "
  ##   assert alignLeft("1232", 6, '#'.Rune) == "1232##"
  ##   assert alignLeft("Åge", 5) == "Åge  "
  ##   assert alignLeft("×", 4, '_'.Rune) == "×___"
  ##   assert alignLeft("Hello ", 9, "×".asRune) == "Hello ×××"
  let sLen = s.runeLen
  if sLen < count:
    let padStr = $padding
    result = newStringOfCap(s.len + (count - sLen) * padStr.len)
    result.add s
    for i in sLen ..< count:
      result.add padStr
  else:
    result = s

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

# --------- Private templates for different split separators -----------
proc stringHasSep(s: string, index: int, seps: openarray[Rune]): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return seps.contains(rune)

proc stringHasSep(s: string, index: int, sep: Rune): bool =
  var rune: Rune
  fastRuneAt(s, index, rune, false)
  return sep == rune

template splitCommon(s, sep, maxsplit: auto, sepLen: int = -1) =
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

iterator split*(s: string, seps: openarray[Rune] = spaceRanges,
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
  splitCommon(s, spaceRanges, -1)

proc splitWhitespace*(s: string): seq[string] {.noSideEffect,
  rtl, extern: "ncuSplitWhitespace".} =
  ## The same as the `splitWhitespace <#splitWhitespace.i,string>`_
  ## iterator, but is a proc that returns a sequence of substrings.
  accumulateResult(splitWhitespace(s))

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
  splitCommon(s, sep, maxsplit, sep.size())

proc split*(s: string, seps: openarray[Rune] = spaceRanges, maxsplit: int = -1): seq[string] {.
  noSideEffect, rtl, extern: "nucSplitRunes".} =
  ## The same as the `split iterator <#split.i,string,openarray[Rune]>`_, but is a
  ## proc that returns a sequence of substrings.
  accumulateResult(split(s, seps, maxsplit))

proc split*(s: string, sep: Rune, maxsplit: int = -1): seq[string] {.noSideEffect,
  rtl, extern: "nucSplitRune".} =
  ## The same as the `split iterator <#split.i,string,Rune>`_, but is a proc
  ## that returns a sequence of substrings.
  accumulateResult(split(s, sep, maxsplit))

proc editDistance*(a, b: string): int {.noSideEffect,
  rtl, extern: "nucEditDistance".} =
  ## Returns the unicode-rune edit distance between ``a`` and ``b``.
  ##
  ## This uses the `Levenshtein`:idx: distance algorithm with only a linear
  ## memory overhead.  This implementation is highly optimized!
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
          inc(char2p, rune_b.size())
        char2p_i = i + 1
        char2p_prev = char2p
      p = offset
      rune_b = b.runeAt(char2p)
      var c3 = row[p] + (if rune_a != rune_b: 1 else: 0)
      inc(char2p, rune_b.size())
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
      inc(char2p, rune_b.size())
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

  block: ## tests for normalizeUnicode
    var expect: string
    expect = "nimprogramminglanguage"
    doAssert(normalizeUnicode("NimProgrammingLanguage") == expect,
      "Actual: " & normalizeUnicode("NimProgrammingLanguage"))
    expect = "nimprogramminglanguage"
    doAssert(normalizeUnicode("Nim_Programming_Language") == expect,
      "Actual: " & normalizeUnicode("Nim_Programming_Language"))
    expect = "nimprogramminglanguage"
    doAssert(normalizeUnicode("Nim_Programming_Language") == expect,
      "Actual: " & normalizeUnicode("Nim_Programming_Language"))
    expect = "nimprogramminglanguageα"
    doAssert(normalizeUnicode("Nim_Programming_Language_Α") == expect,
      "Actual: " & normalizeUnicode("Nim_Programming_Language_Α"))

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

  doAssert isLower("a")
  doAssert isLower("γ")
  doAssert(not isLower("Γ"))
  doAssert(not isLower("4"))
  doAssert(not isLower(""))

  doAssert isLower("abcdγ")
  doAssert(not isLower("abCDΓ"))
  doAssert(not isLower("33aaΓ"))

  doAssert isUpper("Γ")
  doAssert(not isUpper("b"))
  doAssert(not isUpper("α"))
  doAssert(not isUpper("✓"))
  doAssert(not isUpper(""))

  doAssert isUpper("ΑΒΓ")
  doAssert(not isUpper("AAccβ"))
  doAssert(not isUpper("A#$β"))

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

  doAssert(runeSubStr(s, 0) ==  "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, -18) ==  "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, 10) == ": 10,00€")
  doAssert(runeSubStr(s, 18) == "")
  doAssert(runeSubStr(s, 0, 10) == "Hänsel  ««")

  doAssert(runeSubStr(s, 12) == "10,00€")
  doAssert(runeSubStr(s, -6) == "10,00€")

  doAssert(runeSubStr(s, 12, 5) == "10,00")
  doAssert(runeSubStr(s, 12, -1) == "10,00")
  doAssert(runeSubStr(s, -6, 5) == "10,00")
  doAssert(runeSubStr(s, -6, -1) == "10,00")

  doAssert(runeSubStr(s, 0, 100) ==  "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, -100, 100) ==  "Hänsel  ««: 10,00€")
  doAssert(runeSubStr(s, 0, -100) == "")
  doAssert(runeSubStr(s, 100, -100) == "")

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

  block splitTests:
    let s = " this is an example  "
    let s2 = ":this;is;an:example;;"
    let s3 = ":this×is×an:example××"

    doAssert s.split() == @["", "this", "is", "an", "example", "", ""]
    doAssert s2.split(seps = [':'.Rune, ';'.Rune]) == @["", "this", "is", "an", "example", "", ""]
    doAssert s3.split(seps = [':'.Rune, "×".asRune]) == @["", "this", "is", "an", "example", "", ""]
    doAssert s.split(maxsplit = 4) == @["", "this", "is", "an", "example  "]
    doAssert s.split(' '.Rune, maxsplit = 1) == @["", "this is an example  "]

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

  block editDistanceTests:
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

  block runeLenTests:
    doAssert(size('a'.Rune) == 1, "Actual: " & $ size('a'.Rune))

    doAssert("å".runeLenAt(0) == 2, "Actual: " & $ "å".runeLenAt(0))
    doAssert("×".runeLenAt(0) == 2, "Actual: " & $ "×".runeLenAt(0))
