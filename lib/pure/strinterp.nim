#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf, Anatoly Galiulin
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides the string interpolation macro ``fmt``.

import parseutils, sequtils, macros, strutils, unicode, math

# -----------------------------------------------------------------------------
# nimboost's formatters
# -----------------------------------------------------------------------------

proc mkDigit(v: int, lowerCase: bool): string {.inline.} =
  doAssert(v < 26)
  if v < 10:
    result = $chr(ord('0') + v)
  else:
    result = $chr(ord(if lowerCase: 'a' else: 'A') + v - 10)

proc formatInt(n: SomeNumber, radix = 10, len = 0, fill = ' ', lowerCase = false): string =
  ## Converts ``n`` to string. If ``n`` is `SomeReal`, it casts to `int64`.
  ## Conversion is done using ``radix``. If result's length is lesser than
  ## ``len``, it aligns result to the right with ``fill`` char.
  ## If ``len`` is negative, the result is aligned to the left.
  ## If `lowerCase` is true, formatted string will be in the lower case.
  when n is SomeUnsignedInt:
    var v = n.uint64
    let s = false
  else:
    var v = n.int64
    let s = v.int64 < 0
    if s:
      v = v * -1

  if v == 0:
    result = "0"
  else:
    result = ""
    while v > (type(v))0:
      let d = v mod (type(v))radix
      v = v div (type(v))radix
      result.add(mkDigit(d.int, lowerCase))
    for idx in 0..<(result.len div 2):
      swap result[idx], result[result.len - idx - 1]
  var length = abs(len)
  if length == 0 or (s and (result.len >= length - 1)) or (not s and (result.len >= length)):
    if s:
      result = "-" & result
  elif len < 0:
    if s:
      result = "-" & result
    for i in result.len..<length:
      result.add(fill)
  else:
    # The sign must be near the number
    if fill != '0' and s:
      result = "-" & result
    var toFill = length - result.len
    var prefix = repeat(fill, toFill)
    if fill == '0' and s:
      prefix[0] = '-'
    result = prefix & result

proc formatString(s: string, len: int, fill = ' '): string =
  ## Aligns ``s`` using ``fill`` char
  ## - to the right, if ``len`` is positive,
  ## - to the left, if ``len`` is negative,
  ## - or returns ``s`` unaffected, if len is 0.
  let sRuneLen = if s.validateUtf8 == -1: s.runeLen else: s.len
  if len == 0:
    result = s
  else:
    let fillLength = abs(len) - sRuneLen
    if fillLength <= 0:
      result = s
    elif len > 0:
      result = repeat(fill, fillLength) & s
    else:
      result = s & repeat(fill, fillLength)

proc formatFloat(v: SomeNumber, len = 0, prec = 0, sep = '.', fill = ' ',  scientific = false, divisor = 0): string =
  ## Converts ``v`` to string with precision == ``prec``. If result's length
  ## is lesser than ``len``, it aligns result to the right with ``fill`` char.
  ## If ``len`` is negative, the result is aligned to the left.
  var value = v.BiggestFloat
  if divisor > 0:
    value = v.BiggestFloat / pow(2f, divisor.float*10f).BiggestFloat
  else:
    value = v.BiggestFloat / pow(1000f, -divisor.float).BiggestFloat
  let f = if scientific: ffScientific else: if prec == 0: ffDefault else: ffDecimal
  if len > 0 and value < 0 and fill == '0':
    result = "-" & formatString(formatBiggestFloat(-value, f, prec, sep), len-1, fill)
  else:
    result = formatString(formatBiggestFloat(value, f, prec, sep), len, fill)

# -----------------------------------------------------------------------------
# nimboost's richstring
# -----------------------------------------------------------------------------

proc parseIntFmt(fmtp: string): tuple[maxLen: int, fillChar: char] =
  ## Extracts the maxLen and fillChar from an int format string. Examples:
  ## "5" => maxLen = 5, fillChar = ' '
  ## "05" => maxLen = 5, fillChar = '0'
  var maxLen = if fmtp == "": 0 else: parseInt(fmtp)
  var minus = fmtp.len > 0 and fmtp[0] == '-'
  var fillChar = if ((minus and fmtp.len > 1) or fmtp.len > 0) and fmtp[if minus: 1 else: 0] == '0': '0' else: ' '
  (maxLen, fillChar)

proc parseFloatFmt(fmtp: string): tuple[maxLen: int, prec: int, fillChar: char, divisor: int] =
  ## Extracts the maxLen, prec, fillChar, and divisor from a float format string.
  ## The divisor by using IEC/ISO standard binary suffixes. Positive divisor
  ## values correspond to IEC modifiers (base 1024), negative values correspond
  ## to SI modifiers (base 1000).
  ## Examples:
  ## "5.1"  => maxLen = 5, prec = 1, fillChar = ' ', divisor = 0
  ## "05.1" => maxLen = 5, prec = 1, fillChar = '0', divisor = 0
  ## "Ki"   => maxLen = 0, prec = 0, fillChar = ' ', divisor = 1
  ## "Mi"   => maxLen = 0, prec = 0, fillChar = ' ', divisor = 2
  ## "k"    => maxLen = 0, prec = 0, fillChar = ' ', divisor = -1
  ## "M"    => maxLen = 0, prec = 0, fillChar = ' ', divisor = -2
  result.fillChar = ' '
  result.divisor = 0
  if fmtp == "":
    return
  # Parse sign (for left/right alignment)
  var t = ""
  var minus = 1
  var idx = 0
  idx += fmtp.parseWhile(t, {'-'}, idx)
  if t == "-":
    minus = -1
  # Parse fillChar
  idx += fmtp.parseWhile(t, {'0'}, idx)
  if t == "0":
    result.fillChar = '0'
  # Parse maxLen
  idx += fmtp.parseWhile(t, {'0'..'9'}, idx)
  if t != "":
    result.maxLen = minus * parseInt(t)
  # Parse prec
  idx += fmtp.skipWhile({'.'}, idx)
  idx += fmtp.parseWhile(t, {'0'..'9'}, idx)
  if t != "":
    result.prec = parseInt(t)
  # Handle size modification suffix
  let remainder = fmtp[idx..^1]
  if remainder.len > 0:
    case remainder
    of "Ki": result.divisor = 1
    of "Mi": result.divisor = 2
    of "Gi": result.divisor = 3
    of "Ti": result.divisor = 4
    of "Pi": result.divisor = 5
    of "Ei": result.divisor = 6
    of "Zi": result.divisor = 7
    of "Yi": result.divisor = 8
    of "k": result.divisor = -1
    of "M": result.divisor = -2
    of "G": result.divisor = -3
    of "T": result.divisor = -4
    of "P": result.divisor = -5
    of "E": result.divisor = -6
    of "Z": result.divisor = -7
    of "Y": result.divisor = -8
    else:
      quit "Illegal float format suffix: " & remainder

proc handleIntFormat(exp: string, fmtp: string, radix: int, lowerCase = false): NimNode {.compileTime.} =
  let (maxLen, fillChar) = parseIntFmt(fmtp)
  result = newCall(bindSym"formatInt", parseExpr(exp), newLit(radix), newLit(maxLen), newLit(fillChar), newLit(lowerCase))

proc handleDFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  result = handleIntFormat(exp, fmtp, 10)

proc handleXFormat(exp: string, fmtp: string, lowerCase: bool): NimNode {.compileTime.} =
  result = handleIntFormat(exp, fmtp, 16, lowerCase)

proc handleFFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, prec, fillChar, divisor) = parseFloatFmt(fmtp)
  result = newCall(
    bindSym"formatFloat", parseExpr(exp), newLit(maxLen), newLit(prec),
    newLit('.'), newLit(fillChar), newLit(false), newLit(divisor))

proc handleEFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, prec, fillChar, divisor) = parseFloatFmt(fmtp)
  result = newCall(
    bindSym"formatFloat", parseExpr(exp), newLit(maxLen), newLit(prec),
    newLit('.'), newLit(fillChar), newLit(true), newLit(divisor))

proc handleSFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, _) = parseIntFmt(fmtp)
  if maxLen == 0:
    result = parseExpr("$(" & exp & ")")
  else:
    result = newCall(bindSym"formatString", parseExpr("$(" & exp & ")"), newLit(maxLen), newLit(' '))

proc handleFormat(exp: string, fmt: string, nodes: var seq[NimNode]) {.compileTime.} =
  if fmt[1] == '%':
    # converts a double %% into % after an interpolation expression
    nodes.add(parseExpr("$(" & exp & ")"))
    nodes.add(newLit(fmt[1..^1]))
  else:
    const formats = {'d', 'f', 's', 'x', 'X', 'e'}
    var idx = 1
    var fmtm = ""
    var fmtp = ""
    while idx < fmt.len:
      if fmt[idx] in formats:
        fmtm = $fmt[idx]
        fmtp = fmt[1..idx-1]
        break
      inc idx
    if fmtm == "":
      nodes.add(parseExpr("$(" & exp & ")"))
      nodes.add(newLit(fmt))
    else:
      case fmtm
      of "d":
        nodes.add(handleDFormat(exp, fmtp))
      of "x", "X":
        nodes.add(handleXFormat(exp, fmtp, lowerCase = fmtm == "x"))
      of "f":
        nodes.add(handleFFormat(exp, fmtp))
      of "e":
        nodes.add(handleEFormat(exp, fmtp))
      of "s":
        nodes.add(handleSFormat(exp, fmtp))
      else:
        quit "Unknown format \"" & fmtm & "\""
      nodes.add(newLit(fmt[idx+1..^1]))

macro fmt*(fmt: static[string]): untyped =
  ## String interpolation macro with scala-like format specifiers.
  ##
  ## Knows about:
  ## * `d` - decimal number formatter
  ## * `x`, `X` - hex number formatter
  ## * `f` - float number formatter
  ## * `e` - float number formatter (scientific form)
  ## * `s` - string formatter
  ##
  ## Examples:
  ##
  ## .. code-block:: Nim
  ##
  ##   let s = "string"
  ##   assert fmt"${s[0..2].toUpperAscii}" == "STR"
  ##   assert fmt"${-10}%04d" == "-010"
  ##   assert fmt"0x${10}%02X" == "0x0A"
  ##   assert fmt"""${"test"}%-5s""" == "test "
  ##   assert fmt"${1}%.3f" == "1.000"
  ##   assert fmt"Hello, $s!" == "Hello, string!"
  ##   assert fmt"${2*1024}%.3Kif kB" == "2.000 kB"

  proc esc(s: string): string {.inline.} =
    result = newStringOfCap(s.len)
    for ch in s:
      case ch
      of '\xD':
        result.add("\\x0D")
      of '\xA':
        result.add("\\x0A")
      of '\"':
        result.add("\\\"")
      else:
        result.add(ch)

  var nodes: seq[NimNode] = @[]
  var fragments = toSeq(fmt.interpolatedFragments)
  for idx in 0..<fragments.len:
    let k = fragments[idx][0]
    let v = fragments[idx][1]
    case k
    of ikDollar:
      nodes.add(newLit(v))
    of ikStr:
      if v[0] == '%' and v.len > 1 and idx > 0 and fragments[idx-1][0] in {ikVar, ikExpr}:
        nodes.del(nodes.len-1)
        handleFormat(fragments[idx-1][1], v, nodes)
      else:
        nodes.add(parseExpr("\"" & v.esc & "\""))
    else:
      nodes.add(parseExpr("$(" & v & ")"))
  result = newNimNode(nnkStmtList).add(
    foldr(nodes, a.infix("&", b)))


when isMainModule:

  template check(actual, expected: string) =
    if actual != expected:
      let actualLocal {.inject.} = actual
      let expectedLocal {.inject.} = expected
      let msg = fmt"Format error in line ${instantiationInfo(-2).line}: Expected '${expectedLocal}', but got '${actualLocal}'"
      raise newException(AssertionError, msg)

  # Basic tests
  let s = "string"
  check fmt"${s[0..2].toUpperAscii}", "STR"
  check fmt"${-10}%04d", "-010"
  check fmt"0x${10}%02X", "0x0A"
  check fmt"""${"test"}%-5s""", "test "
  check fmt"${1}%.3f", "1.000"
  check fmt"Hello, $s!", "Hello, string!"
  check fmt"${2*1024}%.3Kif kB", "2.000 kB"

  # Tests for identifers without parenthesis
  check fmt"$s works$s", "string worksstring"
  check fmt"$s|works$s", "string|worksstring"
  check fmt"$s.works$s", "string.worksstring"
  check fmt"$s-works$s", "string-worksstring"
  check fmt"$s%7s", " string"
  doAssert(not compiles(fmt"$s_works")) # parsed as identifier `s_works`

  # Misc general tests
  check fmt"$$", "$"
  check fmt"${0}%%", "0%"
  check fmt"${0}%%asdf", "0%asdf"
  check fmt"""\n${"\n"}\n""", "\n\n\n"
  check fmt"""${"abc"}%ss""", "abcs"

  # String tests
  check fmt"""${"abc"}""", "abc"
  check fmt"""${"abc"}%s""", "abc"
  check fmt"""${"abc"}%1s""", "abc"
  check fmt"""${"abc"}%+1s""", "abc"
  check fmt"""${"abc"}%-1s""", "abc"
  check fmt"""${"abc"}%4s""", " abc"
  check fmt"""${"abc"}%-4s""", "abc "
  check fmt"""${""}%4s""", "    "
  check fmt"""${""}%-4s""", "    "

  # Unicode string tests
  check fmt"""${"αβγ"}""", "αβγ"
  check fmt"""${"αβγ"}%5s""", "  αβγ"
  check fmt"""${"αβγ"}%-5s""", "αβγ  "
  check fmt"""a${"a"}α${"α"}€${"€"}𐍈${"𐍈"}""", "aaαα€€𐍈𐍈"
  check fmt"""a${"a"}%-2sα${"α"}%-2s€${"€"}%-2s𐍈${"𐍈"}%-2s""", "aa αα €€ 𐍈𐍈 "
  # Invalid unicode sequences should be handled as plain strings.
  # Invalid examples taken from: https://stackoverflow.com/a/3886015/1804173
  let invalidUtf8 = [
    "\xc3\x28", "\xa0\xa1",
    "\xe2\x28\xa1", "\xe2\x82\x28",
    "\xf0\x28\x8c\xbc", "\xf0\x90\x28\xbc", "\xf0\x28\x8c\x28"
  ]
  for s in invalidUtf8:
    check fmt"$s%5s", repeat(" ", 5-s.len) & s

  # Int tests
  check fmt"${12345}", "12345"
  check fmt"${ - 12345}", "-12345"
  check fmt"${12345}%6d", " 12345"
  check fmt"${12345}%-6d", "12345 "
  check fmt"${12345}%4d", "12345"
  check fmt"${12345}%-4d", "12345"
  check fmt"${12345}%08d", "00012345"
  check fmt"${-12345}%08d", "-0012345"
  check fmt"${0}%0d", "0"
  check fmt"${0}%02d", "00"
  check fmt"${-1}%3d", " -1"
  check fmt"${-1}%03d", "-01"
  check fmt"${10}", "10"
  check fmt"${16}%X", "10"
  doAssert(not compiles(fmt"""${"12345"}%d"""))

  # Float tests
  check fmt"${123.456}", "123.456"
  check fmt"${-123.456}", "-123.456"
  check fmt"${123.456}%f", "123.456"
  check fmt"${-123.456}%f", "-123.456"
  check fmt"${123.456}%1f", "123.456" # no truncation
  check fmt"${123.456}%.1f", "123.5"
  check fmt"${123.456}%9.4f", " 123.4560"
  check fmt"${123.456}%-9.4f", "123.4560 "
  doAssert(not compiles(fmt"""${"12345"}%f"""))

  # Float (scientific) tests
  check fmt"${123.456}%e", "1.234560e+02"
  check fmt"${123.456}%13e", " 1.234560e+02"
  check fmt"${123.456}%-13e", "1.234560e+02 "
  check fmt"${123.456}%.1e", "1.2e+02"
  check fmt"${123.456}%.2e", "1.23e+02"
  check fmt"${123.456}%.3e", "1.235e+02"
  doAssert(not compiles(fmt"""${"12345"}%e"""))

  # Float size modifier tests
  check fmt"${1024}%Kif", "1"
  check fmt"${1024*1024}%Mif", "1"
  check fmt"${1024*1024*1024}%Gif", "1"
  check fmt"${1_000}%kf", "1"
  check fmt"${1_000_000}%Mf", "1"
  check fmt"${1_000_000_000}%Gf", "1"
  check fmt"${pow(2f, 10f)}%Kif", "1"
  check fmt"${pow(2f, 20f)}%Mif", "1"
  check fmt"${pow(2f, 30f)}%Gif", "1"
  check fmt"${pow(2f, 40f)}%Tif", "1"
  check fmt"${pow(2f, 50f)}%Pif", "1"
  check fmt"${pow(2f, 60f)}%Eif", "1"
  check fmt"${pow(2f, 70f)}%Zif", "1"
  check fmt"${pow(2f, 80f)}%Yif", "1"
  check fmt"${pow(1000f, 1f)}%kf", "1"
  check fmt"${pow(1000f, 2f)}%Mf", "1"
  check fmt"${pow(1000f, 3f)}%Gf", "1"
  check fmt"${pow(1000f, 4f)}%Tf", "1"
  check fmt"${pow(1000f, 5f)}%Pf", "1"
  check fmt"${pow(1000f, 6f)}%Ef", "1"
  check fmt"${pow(1000f, 7f)}%Zf", "1"
  check fmt"${pow(1000f, 8f)}%Yf", "1"
  check fmt"${1024}%KifkB", "1kB"
  check fmt"${1024}%.3Kif", "1.000"

  # Hex tests
  check fmt"${0}%x", "0"
  check fmt"${-0}%x", "0"
  check fmt"${255}%x", "ff"
  check fmt"${255}%X", "FF"
  check fmt"${-255}%x", "-ff"
  check fmt"${-255}%X", "-FF"
  check fmt"${255}%x uNaffeCteD CaSe", "ff uNaffeCteD CaSe"
  check fmt"${255}%X uNaffeCteD CaSe", "FF uNaffeCteD CaSe"
  check fmt"${255}%4x", "  ff"
  check fmt"${255}%04x", "00ff"
  check fmt"${-255}%4x", " -ff"
  check fmt"${-255}%04x", "-0ff"
  doAssert(not compiles(fmt"""${"12345"}%x"""))
  doAssert(not compiles(fmt"""${"12345"}%X"""))
