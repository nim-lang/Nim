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


template parseFloatThousandSepImpl(str; sep: char; decimalDot: char): float =
  assert sep != '-' and decimalDot notin {'-', ' '} and sep != decimalDot

  proc raiseError(i: int; c: char; s: string) {.noinline, noreturn.} =
    raise newException(ValueError,
      "Invalid float containing thousand separators, invalid char $1 at index $2 for input $3" %
      [c.repr, $i, s])

  var s = newStringOfCap(str.len)
  var successive: int
  var afterDot, lastWasDot, lastWasSep, hasAnySep, isNegative: bool
  for idx, c in str:
    if c in '0' .. '9':  # Digits
      if hasAnySep and successive > 2:
        raiseError(idx, c, $str)
      else:
        s.add c
        lastWasSep = false
        lastWasDot = false
        inc successive
    if c == sep:  # Thousands separator, this is NOT the dot
      if lastWasSep or afterDot or (isNegative and idx == 1 or idx == 0):
        raiseError(idx, c, $str)
      else:
        lastWasSep = true # Do NOT add the Thousands separator here.
        hasAnySep = true
        successive = 0
    if c == decimalDot:  # This is the dot
      if (isNegative and idx == 1 or idx == 0) or (hasAnySep and successive != 3):  # Disallow .1
        raiseError(idx, c, $str)
      else:
        s.add '.' # Replace decimalDot to '.' so parseFloat can take it.
        successive = 0
        lastWasDot = true
        afterDot = true
    if c == '-':  # Allow negative float
      if isNegative or idx != 0:  # Disallow ---1.0
        raiseError(idx, c, $str)
      else:
        s.add '-'
        isNegative = true
  parseFloat(s)


func parseFloatThousandSep*(s: string; sep = ','; decimalDot = '.'): float {.since: (1, 5).} =
  ## Convenience func for `parseFloat` which allows for thousand separators,
  ## this is designed to parse floats as found in the wild formatted for humans.
  ##
  ## The following assumptions and requirements must be met:
  ## - String must not be empty.
  ## - String must be stripped of trailing and leading whitespaces.
  ## - `sep` must not be `'-'`.
  ## - `decimalDot` must not be `'-'` nor `' '`.
  ## - `sep` and `decimalDot` must be different.
  ## - Exactly 1 separator must appear after each 3 consecutive inner digits to the left of the dot and nowhere else.
  ##
  ## See also:
  ## * `parseFloat <strutils.html#parseFloat,string>`_
  runnableExamples:
    doAssert parseFloatThousandSep("1,000") == 1000.0
    doAssert parseFloatThousandSep("-1,000") == -1000.0
    doAssert parseFloatThousandSep("10,000.000") == 10000.0
    doAssert parseFloatThousandSep("1,000,000.000") == 1000000.0
    doAssert parseFloatThousandSep("10,000,000.000") == 10000000.0
    doAssert parseFloatThousandSep("10.000,0", '.', ',') == 10000.0
    doAssert parseFloatThousandSep("1'000'000,000", '\'', ',') == 1000000.0
  if s.len > 1: parseFloatThousandSepImpl(s, sep, decimalDot) else: parseFloat(s)


func parseFloatThousandSep*(s: openArray[char]; sep = ','; decimalDot = '.'): float {.since: (1, 5).} =
  runnableExamples:
    doAssert parseFloatThousandSep(['1', ',', '0', '0', '0']) == 1000.0
    doAssert parseFloatThousandSep(['-', '1', ',', '0', '0', '0']) == -1000.0
    doAssert parseFloatThousandSep(['1', '0', ',', '0', '0', '0', '.', '0', '0', '0']) == 10000.0
    doAssert parseFloatThousandSep(['1', '0', '.', '0', '0', '0', ',', '0'], '.', ',') == 10000.0
  if s.len > 1: parseFloatThousandSepImpl(s, sep, decimalDot) else: parseFloat($s[0])


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
