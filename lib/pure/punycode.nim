#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements a representation of Unicode with the limited
## ASCII character subset.

import strutils
import unicode

# issue #3045

const
  Base = 36
  TMin = 1
  TMax = 26
  Skew = 38
  Damp = 700
  InitialBias = 72
  InitialN = 128
  Delimiter = '-'

type
  PunyError* = object of ValueError

proc decodeDigit(x: char): int {.raises: [PunyError].} =
  if '0' <= x and x <= '9':
    result = ord(x) - (ord('0') - 26)
  elif 'A' <= x and x <= 'Z':
    result = ord(x) - ord('A')
  elif 'a' <= x and x <= 'z':
    result = ord(x) - ord('a')
  else:
    raise newException(PunyError, "Bad input")

proc encodeDigit(digit: int): Rune {.raises: [PunyError].} =
  if 0 <= digit and digit < 26:
    result = Rune(digit + ord('a'))
  elif 26 <= digit and digit < 36:
    result = Rune(digit + (ord('0') - 26))
  else:
    raise newException(PunyError, "internal error in punycode encoding")

proc isBasic(c: char): bool = ord(c) < 0x80
proc isBasic(r: Rune): bool = int(r) < 0x80

proc adapt(delta, numPoints: int, first: bool): int =
  var d = if first: delta div Damp else: delta div 2
  d += d div numPoints
  var k = 0
  while d > ((Base-TMin)*TMax) div 2:
    d = d div (Base - TMin)
    k += Base
  result = k + (Base - TMin + 1) * d div (d + Skew)

proc encode*(prefix, s: string): string {.raises: [PunyError].} =
  ## Encode a string that may contain Unicode.
  ## Prepend `prefix` to the result
  result = prefix
  var (d, n, bias) = (0, InitialN, InitialBias)
  var (b, remaining) = (0, 0)
  for r in s.runes:
    if r.isBasic:
      # basic Ascii character
      inc b
      result.add($r)
    else:
      # special character
      inc remaining

  var h = b
  if b > 0:
    result.add(Delimiter) # we have some Ascii chars
  while remaining != 0:
    var m: int = high(int32)
    for r in s.runes:
      if m > int(r) and int(r) >= n:
        m = int(r)
    d += (m - n) * (h + 1)
    if d < 0:
      raise newException(PunyError, "invalid label " & s)
    n = m
    for r in s.runes:
      if int(r) < n:
        inc d
        if d < 0:
          raise newException(PunyError, "invalid label " & s)
        continue
      if int(r) > n:
        continue
      var q = d
      var k = Base
      while true:
        var t = k - bias
        if t < TMin:
          t = TMin
        elif t > TMax:
          t = TMax
        if q < t:
          break
        result.add($encodeDigit(t + (q - t) mod (Base - t)))
        q = (q - t) div (Base - t)
        k += Base
      result.add($encodeDigit(q))
      bias = adapt(d, h + 1, h == b)
      d = 0
      inc h
      dec remaining
    inc d
    inc n

proc encode*(s: string): string {.raises: [PunyError].} =
  ## Encode a string that may contain Unicode. Prefix is empty.
  result = encode("", s)

proc decode*(encoded: string): string {.raises: [PunyError].} =
  ## Decode a Punycode-encoded string
  var
    n = InitialN
    i = 0
    bias = InitialBias
  var d = rfind(encoded, Delimiter)
  result = ""

  if d > 0:
    # found Delimiter
    for j in 0..<d:
      var c = encoded[j] # char
      if not c.isBasic:
        raise newException(PunyError, "Encoded contains a non-basic char")
      result.add(c) # add the character
    inc d
  else:
    d = 0 # set to first index

  while (d < len(encoded)):
    var oldi = i
    var w = 1
    var k = Base
    while true:
      if d == len(encoded):
        raise newException(PunyError, "Bad input: " & encoded)
      var c = encoded[d]; inc d
      var digit = int(decodeDigit(c))
      if digit > (high(int32) - i) div w:
        raise newException(PunyError, "Too large a value: " & $digit)
      i += digit * w
      var t: int
      if k <= bias:
        t = TMin
      elif k >= bias + TMax:
        t = TMax
      else:
        t = k - bias
      if digit < t:
        break
      w *= Base - t
      k += Base
    bias = adapt(i - oldi, runeLen(result) + 1, oldi == 0)

    if i div (runeLen(result) + 1) > high(int32) - n:
      raise newException(PunyError, "Value too large")

    n += i div (runeLen(result) + 1)
    i = i mod (runeLen(result) + 1)
    insert(result, $Rune(n), i)
    inc i


runnableExamples:
  static:
    block:
      doAssert encode("") == ""
      doAssert encode("a") == "a-"
      doAssert encode("A") == "A-"
      doAssert encode("3") == "3-"
      doAssert encode("-") == "--"
      doAssert encode("--") == "---"
      doAssert encode("abc") == "abc-"
      doAssert encode("London") == "London-"
      doAssert encode("Lloyd-Atkinson") == "Lloyd-Atkinson-"
      doAssert encode("This has spaces") == "This has spaces-"
      doAssert encode("ü") == "tda"
      doAssert encode("München") == "Mnchen-3ya"
      doAssert encode("Mnchen-3ya") == "Mnchen-3ya-"
      doAssert encode("München-Ost") == "Mnchen-Ost-9db"
      doAssert encode("Bahnhof München-Ost") == "Bahnhof Mnchen-Ost-u6b"
    block:
      doAssert decode("") == ""
      doAssert decode("a-") ==  "a"
      doAssert decode("A-") == "A"
      doAssert decode("3-") == "3"
      doAssert decode("--") == "-"
      doAssert decode("---") == "--"
      doAssert decode("abc-") == "abc"
      doAssert decode("London-") == "London"
      doAssert decode("Lloyd-Atkinson-") == "Lloyd-Atkinson"
      doAssert decode("This has spaces-") == "This has spaces"
      doAssert decode("tda") == "ü"
      doAssert decode("Mnchen-3ya") == "München"
      doAssert decode("Mnchen-3ya-") == "Mnchen-3ya"
      doAssert decode("Mnchen-Ost-9db") == "München-Ost"
      doAssert decode("Bahnhof Mnchen-Ost-u6b") == "Bahnhof München-Ost"
