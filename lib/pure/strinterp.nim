#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Anatoly Galiulin
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides the string interpolation macro ``fmt``.

import parseutils, sequtils, macros, strutils

# -----------------------------------------------------------------------------
# nimboost's formatters
# -----------------------------------------------------------------------------

proc mkDigit(v: int, lowerCase: bool): string {.inline.} =
  doAssert(v < 26)
  if v < 10:
    result = $chr(ord('0') + v)
  else:
    result = $chr(ord(if lowerCase: 'a' else: 'A') + v - 10)

proc intToStr(n: SomeNumber, radix = 10, len = 0, fill = ' ', lowerCase = false): string =
  ## Converts ``n`` to string. If ``n`` is `SomeReal`, it casts to `int64`.
  ## Conversion is done using ``radix``. If result's length is lesser then
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
    if fill != '0':
      # The sign must be near the number
      if s:
        result = "-" & result
    var toFill = length - result.len
    var prefix = newString(toFill)
    for idx in 0..<toFill:
      prefix[idx] = fill
    if fill == '0' and s:
      prefix[0] = '-'
    result = prefix & result

proc alignStr(s: string, len: int, fill = ' ', trunc = false): string =
  ## Aligns ``s`` using ``fill`` char to the right if ``len`` is
  ## positive, or to the left, if ``len`` is negative.
  ## If the length of ``s`` is bigger then `abs(len)` and ``trunc`` == true,
  ## truncates ``s``
  if len == 0:
    result = s
  elif trunc and s.len > abs(len):
    result = s
    result.setLen(abs(len))
  else:
    let fillLength = abs(len) - s.len
    if fillLength <= 0:
      result = s
    elif len > 0:
      result = repeat(fill, fillLength) & s
    else:
      result = s & repeat(fill, fillLength)

proc floatToStr(v: SomeNumber, len = 0, prec = 0, sep = '.', fill = ' ',  scientific = false): string =
  ## Converts ``v`` to string with precision == ``prec``. If result's length
  ## is lesser then ``len``, it aligns result to the right with ``fill`` char.
  ## If ``len`` is negative, the result is aligned to the left.
  let f = if scientific: ffScientific else: if prec == 0: ffDefault else: ffDecimal
  if len > 0 and v < 0 and fill == '0':
    result = "-" & alignStr(formatBiggestFloat(-v.BiggestFloat, f, prec, sep), len-1, fill)
  else:
    result = alignStr(formatBiggestFloat(v.BiggestFloat, f, prec, sep), len, fill)

# -----------------------------------------------------------------------------
# nimboost's richstring
# -----------------------------------------------------------------------------

proc parseIntFmt(fmtp: string): tuple[maxLen: int, fillChar: char] =
  var maxLen = if fmtp == "": 0 else: parseInt(fmtp)
  var minus = fmtp.len > 0 and fmtp[0] == '-'
  var fillChar = if ((minus and fmtp.len > 1) or fmtp.len > 0) and fmtp[if minus: 1 else: 0] == '0': '0' else: ' '
  (maxLen, fillChar)

proc parseFloatFmt(fmtp: string): tuple[maxLen: int, prec: int, fillChar: char] =
  result.fillChar = ' '
  if fmtp == "":
    return
  var t = ""
  var minus = 1
  var idx = 0
  idx += fmtp.parseWhile(t, {'-'}, idx)
  if t == "-":
    minus = -1
  idx += fmtp.parseWhile(t, {'0'}, idx)
  if t == "0":
    result.fillChar = '0'
  idx += fmtp.parseWhile(t, {'0'..'9'}, idx)
  if t != "":
    result.maxLen = minus * parseInt(t)
  idx += fmtp.skipWhile({'.'}, idx)
  idx += fmtp.parseWhile(t, {'0'..'9'}, idx)
  if t != "":
    result.prec = parseInt(t)

proc handleIntFormat(exp: string, fmtp: string, radix: int, lowerCase = false): NimNode {.compileTime.} =
  let (maxLen, fillChar) = parseIntFmt(fmtp)
  result = newCall(bindSym"intToStr", parseExpr(exp), newLit(radix), newLit(maxLen), newLit(fillChar), newLit(lowerCase))

proc handleDFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  result = handleIntFormat(exp, fmtp, 10)

proc handleXFormat(exp: string, fmtp: string, lowerCase: bool): NimNode {.compileTime.} =
  result = handleIntFormat(exp, fmtp, 16, lowerCase)

proc handleFFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, prec, fillChar) = parseFloatFmt(fmtp)
  result = newCall(bindSym"floatToStr", parseExpr(exp), newLit(maxLen), newLit(prec), newLit('.'), newLit(fillChar), newLit(false))

proc handleEFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, prec, fillChar) = parseFloatFmt(fmtp)
  result = newCall(bindSym"floatToStr", parseExpr(exp), newLit(maxLen), newLit(prec), newLit('.'), newLit(fillChar), newLit(true))

proc handleSFormat(exp: string, fmtp: string): NimNode {.compileTime.} =
  var (maxLen, _) = parseIntFmt(fmtp)
  if maxLen == 0:
    result = parseExpr("$(" & exp & ")")
  else:
    result = newCall(bindSym"alignStr", parseExpr("$(" & exp & ")"), newLit(maxLen), newLit(' '))

proc handleFormat(exp: string, fmt: string, nodes: var seq[NimNode]) {.compileTime} =
  if fmt[1] == '%':
    nodes.add(parseExpr("$(" & exp & ")"))
    nodes.add(newLit(fmt[1..^1]))
  else:
    const formats = {'d', 'f', 's', 'x', 'X', 'e'}
    var idx = 1
    var fmtm = ""
    var fmtp = ""
    while idx < fmt.len:
      if fmt[idx].isAlphaAscii:
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
      echo fmt"Format error in line ${instantiationInfo(-2).line}: Expected '${expectedLocal}', but got '${actualLocal}'"
      doAssert actual == expected

  # Basic tests
  let s = "string"
  check fmt"${s[0..2].toUpperAscii}", "STR"
  check fmt"${-10}%04d", "-010"
  check fmt"0x${10}%02X", "0x0A"
  check fmt"""${"test"}%-5s""", "test "
  check fmt"${1}%.3f", "1.000"
  check fmt"Hello, $s!", "Hello, string!"

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

  # Int tests
  check fmt"${12345}", "12345"
  check fmt"${ - 12345}", "-12345"
  check fmt"${12345}%6d", " 12345"
  check fmt"${12345}%-6d", "12345 "
  check fmt"${12345}%4d", "12345"
  check fmt"${12345}%-4d", "12345"
  check fmt"${12345}%08d", "00012345"
  check fmt"${-12345}%08d", "-0012345"
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
