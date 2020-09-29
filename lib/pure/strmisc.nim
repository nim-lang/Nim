#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Joey Payne
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains various string utility routines that are uncommonly
## used in comparison to `strutils <strutils.html>`_.

import strutils
import std/private/since

proc expandTabs*(s: string, tabSize: int = 8): string {.noSideEffect.} =
  ## Expand tab characters in `s` replacing them by spaces.
  ##
  ## The amount of inserted spaces for each tab character is the difference
  ## between the current column number and the next tab position. Tab positions
  ## occur every `tabSize` characters.
  ## The column number starts at 0 and is increased with every single character
  ## and inserted space, except for newline, which resets the column number
  ## back to 0.
  runnableExamples:
    doAssert expandTabs("\t", 4) == "    "
    doAssert expandTabs("\tfoo\t", 4) == "    foo "
    doAssert expandTabs("\tfoo\tbar", 4) == "    foo bar"
    doAssert expandTabs("\tfoo\tbar\t", 4) == "    foo bar "
    doAssert expandTabs("ab\tcd\n\txy\t", 3) == "ab cd\n   xy "

  result = newStringOfCap(s.len + s.len shr 2)
  var pos = 0

  template addSpaces(n) =
    for j in 0 ..< n:
      result.add(' ')
      pos += 1

  for i in 0 ..< len(s):
    let c = s[i]
    if c == '\t':
      let
        denominator = if tabSize > 0: tabSize else: 1
        numSpaces = tabSize - pos mod denominator

      addSpaces(numSpaces)
    else:
      result.add(c)
      pos += 1
    if c == '\l':
      pos = 0

proc partition*(s: string, sep: string,
                right: bool = false): (string, string, string)
                {.noSideEffect.} =
  ## Split the string at the first or last occurrence of `sep` into a 3-tuple
  ##
  ## Returns a 3 string tuple of (beforeSep, `sep`, afterSep) or
  ## (`s`, "", "") if `sep` is not found and `right` is false or
  ## ("", "", `s`) if `sep` is not found and `right` is true
  runnableExamples:
    doAssert partition("foo:bar", ":") == ("foo", ":", "bar")
    doAssert partition("foobarbar", "bar") == ("foo", "bar", "bar")
    doAssert partition("foobarbar", "bank") == ("foobarbar", "", "")
    doAssert partition("foobarbar", "foo") == ("", "foo", "barbar")
    doAssert partition("foofoobar", "bar") == ("foofoo", "bar", "")

  let position = if right: s.rfind(sep) else: s.find(sep)
  if position != -1:
    return (s[0 ..< position], sep, s[position + sep.len ..< s.len])
  return if right: ("", "", s) else: (s, "", "")

proc rpartition*(s: string, sep: string): (string, string, string)
                {.noSideEffect.} =
  ## Split the string at the last occurrence of `sep` into a 3-tuple
  ##
  ## Returns a 3 string tuple of (beforeSep, `sep`, afterSep) or
  ## ("", "", `s`) if `sep` is not found
  runnableExamples:
    doAssert rpartition("foo:bar", ":") == ("foo", ":", "bar")
    doAssert rpartition("foobarbar", "bar") == ("foobar", "bar", "")
    doAssert rpartition("foobarbar", "bank") == ("", "", "foobarbar")
    doAssert rpartition("foobarbar", "foo") == ("", "foo", "barbar")
    doAssert rpartition("foofoobar", "bar") == ("foofoo", "bar", "")

  return partition(s, sep, right = true)


template parseFloatThousandSepImpl(s: var string; sep: static char; decimalDot: static char): float =
  assert sep notin {'-', ' '} and decimalDot notin {'-', ' '} and sep != decimalDot

  template bail(m: string) =
    raise newException(ValueError, "Invalid float containing thousand separators, " & m)

  if likely(s.len > 1): # Allow "0" thats valid, is 0.0
    var idx, successive: int
    var afterDot, lastWasDot, lastWasSep, hasAnySep, isNegative: bool
    while idx < s.len:
      case s[idx]
      of '0' .. '9':  # Digits
        if hasAnySep and successive > 2:
          bail("more than 3 digits between thousand separators.")
        else:
          lastWasSep = false
          lastWasDot = false
          inc successive
          inc idx
      of sep:  # Thousands separator
        if unlikely(isNegative and idx == 1 or idx == 0):
          bail("string starts with thousand separator.")
        elif lastWasSep:
          bail("two separators in a row.")
        elif afterDot:
          bail("separator found after decimal dot.")
        else:
          s.delete(idx, idx)
          lastWasSep = true
          hasAnySep = true
          successive = 0
      of decimalDot:
        if unlikely(isNegative and idx == 1 or idx == 0):  # Wont allow .1
          bail("string starts with decimal dot.")
        elif hasAnySep and successive != 3:
          bail("not 3 successive digits before decimal point, despite larger 1000.")
        else:
          when decimalDot != '.':
            s[idx] = '.'  # Replace decimalDot to '.' so parseFloat can take it.
          successive = 0
          lastWasDot = true
          afterDot = true
          inc idx
      of '-':  # Allow negative float
        if unlikely(isNegative):  # Wont allow ---1.0
          bail("string must not contain more than 1 '-' character.")
        else:
          isNegative = true
          inc idx
      else:
        bail("invalid character in float: " & $s[idx])
  parseFloat(s)


func parseFloatThousandSep*(s: string; sep: static char = ','; decimalDot: static char = '.'): float {.since: (1, 3).} =
  ## Convenience func for `parseFloat` which allows for thousand separators,
  ## this is designed to parse floats as found in the wild formatted for humans.
  ##
  ## The following assumptions and requirements must be met:
  ## - String must not be empty.
  ## - String must be stripped of trailing and leading whitespaces.
  ## - `sep` must not be `'-'` nor `' '`.
  ## - `decimalDot` must not be `'-'` nor `' '`.
  ## - `sep` and `decimalDot` must be different.
  ## - No separator before a digit.
  ## - First separator can be anywhere after first digit, but no more than 3 characters.
  ## - There has to be 3 digits between successive separators.
  ## - There has to be 3 digits between the last separator and the decimal dot.
  ## - No separator after decimal dot.
  ## - No duplicate separators.
  ## - Floats without separator allowed.
  ##
  ## See also:
  ## * `strutils <strutils.html>`_
  runnableExamples:
    doAssert parseFloatThousandSep("0") == 0.0
    doAssert parseFloatThousandSep("-0") == -0.0
    doAssert parseFloatThousandSep("0.0") == 0.0
    doAssert parseFloatThousandSep("1.0") == 1.0
    doAssert parseFloatThousandSep("-0.0") == -0.0
    doAssert parseFloatThousandSep("-1.0") == -1.0
    doAssert parseFloatThousandSep("1.000") == 1.0
    doAssert parseFloatThousandSep("-1.000") == -1.0
    doAssert parseFloatThousandSep("1,000") == 1000.0
    doAssert parseFloatThousandSep("-1,000") == -1000.0
    doAssert parseFloatThousandSep("10,000.000") == 10000.0
    doAssert parseFloatThousandSep("1,000,000.000") == 1000000.0
    doAssert parseFloatThousandSep("10,000,000.000") == 10000000.0
    doAssert parseFloatThousandSep("10.000,0", '.', ',') == 10000.0
    doAssert parseFloatThousandSep("1'000'000,000", '\'', ',') == 1000000.0
  var copiedString = s
  parseFloatThousandSepImpl(copiedString, sep, decimalDot)


func parseFloatThousandSep*(s: var string; sep: static char = ','; decimalDot: static char = '.'): float {.since: (1, 3).} =
  ## In-place version of `parseFloatThousandSep`, does not copy the string internally.
  runnableExamples:
    var a = "0"
    doAssert parseFloatThousandSep(a) == 0.0
    var b = "-0"
    doAssert parseFloatThousandSep(b) == -0.0
    var c = "0.0"
    doAssert parseFloatThousandSep(c) == 0.0
    var d = "1.0"
    doAssert parseFloatThousandSep(d) == 1.0
    var e = "-0.0"
    doAssert parseFloatThousandSep(e) == -0.0
    var f = "-1.0"
    doAssert parseFloatThousandSep(f) == -1.0
    var g = "1.000"
    doAssert parseFloatThousandSep(g) == 1.0
    var h = "-1.000"
    doAssert parseFloatThousandSep(h) == -1.0
    var i = "1,000"
    doAssert parseFloatThousandSep(i) == 1000.0
    var j = "-1,000"
    doAssert parseFloatThousandSep(j) == -1000.0
    var k = "10,000.000"
    doAssert parseFloatThousandSep(k) == 10000.0
    var l = "1,000,000.000"
    doAssert parseFloatThousandSep(l) == 1000000.0
    var m = "10,000,000.000"
    doAssert parseFloatThousandSep(m) == 10000000.0
    var n = "10.000,0"
    doAssert parseFloatThousandSep(n, '.', ',') == 10000.0
    var o = "1'000'000,000"
    doAssert parseFloatThousandSep(o, '\'', ',') == 1000000.0
  parseFloatThousandSepImpl(s, sep, decimalDot)


when isMainModule:
  doAssert expandTabs("\t", 4) == "    "
  doAssert expandTabs("\tfoo\t", 4) == "    foo "
  doAssert expandTabs("\tfoo\tbar", 4) == "    foo bar"
  doAssert expandTabs("\tfoo\tbar\t", 4) == "    foo bar "
  doAssert expandTabs("", 4) == ""
  doAssert expandTabs("", 0) == ""
  doAssert expandTabs("\t\t\t", 0) == ""

  doAssert partition("foo:bar", ":") == ("foo", ":", "bar")
  doAssert partition("foobarbar", "bar") == ("foo", "bar", "bar")
  doAssert partition("foobarbar", "bank") == ("foobarbar", "", "")
  doAssert partition("foobarbar", "foo") == ("", "foo", "barbar")
  doAssert partition("foofoobar", "bar") == ("foofoo", "bar", "")

  doAssert rpartition("foo:bar", ":") == ("foo", ":", "bar")
  doAssert rpartition("foobarbar", "bar") == ("foobar", "bar", "")
  doAssert rpartition("foobarbar", "bank") == ("", "", "foobarbar")
  doAssert rpartition("foobarbar", "foo") == ("", "foo", "barbar")
  doAssert rpartition("foofoobar", "bar") == ("foofoo", "bar", "")
