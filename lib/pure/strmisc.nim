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


since (1, 5):
  type ParseFloatOptions* = enum  ## Options for `parseFloatThousandSep`.
    pfLeadingDot,    ## Allow leading dot, like ".9" and similar.
    pfTrailingDot,   ## Allow trailing dot, like "9." and similar.
    pfSepAnywhere,   ## Allow separator anywhere in between, like "9,9", "9,99".
    pfDotOptional    ## Allow "9", "-0", integer literals, etc.
    pfNanInf         ## Allow "NaN", "Inf", "-Inf", etc.

  func parseFloatThousandSep*(str: openArray[char]; options: set[ParseFloatOptions] = {};
      sep = ','; decimalDot = '.'): float =
    ## Convenience func for `parseFloat` which allows for thousand separators,
    ## this is designed to parse floats as found in the wild formatted for humans.
    ##
    ## Fine grained flexibility and strictness is up to the user,
    ## you can set the `options` using `ParseFloatOptions` enum.
    ##
    ## `parseFloatThousandSep` "prepares" `str` and then calls `parseFloat`,
    ## consequently `parseFloatThousandSep` by design is slower than `parseFloat`.
    ##
    ## The following assumptions and requirements must be met:
    ## - `str` must not be empty string.
    ## - `str` must be stripped of trailing and leading whitespaces.
    ## - `sep` and `decimalDot` must be different.
    ## - `sep` must not be in `{'-', '+', 'e', 'i', 'n', 'f', 'a', '\n'}`.
    ## - `decimalDot` must not be in `{'-', '+', 'e', 'i', 'n', 'f', 'a', ' ', '\t', '\v', '\c', '\n', '\f'}`.
    ##
    ## See also:
    ## * `parseFloat <strutils.html#parseFloat,string>`_
    runnableExamples:
      doAssert parseFloatThousandSep("10,000,000.000") == 10000000.0
      doAssert parseFloatThousandSep("1,222.0001") == 1222.0001
      doAssert parseFloatThousandSep("10.000,0", {}, '.', ',') == 10000.0
      doAssert parseFloatThousandSep("1'000'000,000", {}, '\'', ',') == 1000000.0
      doAssert parseFloatThousandSep("1000000", {pfDotOptional}) == 1000000.0
      doAssert parseFloatThousandSep("-1,000", {pfDotOptional}) == -1000.0
      ## You can omit `sep`, but then all subsequent `sep` to the left must also be omitted:
      doAssert parseFloatThousandSep("1000,000", {pfDotOptional}) == 1000000.0
      ## Examples using different ParseFloatOptions:
      doAssert parseFloatThousandSep(".1", {pfLeadingDot}) == 0.1
      doAssert parseFloatThousandSep("1", {pfDotOptional}) == 1.0
      doAssert parseFloatThousandSep("1.", {pfTrailingDot}) == 1.0
      doAssert parseFloatThousandSep("10,0.0,0,0", {pfSepAnywhere}) == 100.0
      doAssert parseFloatThousandSep("01.00") == 1.0
      doAssert parseFloatThousandSep("1,000.000e-9") == 1e-06

    assert decimalDot notin {'-', '+', 'e', 'i', 'n', 'f', 'a', ' ', '\t', '\v', '\c', '\n', '\f'}
    assert sep notin {'-', '+', 'e', 'i', 'n', 'f', 'a', '\n'}
    assert sep != decimalDot

    proc parseFloatThousandSepRaise(i: int; c: char; s: openArray[char]) {.noinline, noreturn.} =
      raise newException(ValueError,
        "Invalid float containing thousand separators, invalid char $1 at index $2 for input $3" %
        [$c, $i, $s])

    # Fail fast, before looping.
    let strLen = str.len
    if strLen == 0: # Empty string.
      parseFloatThousandSepRaise(0, ' ', "empty string")
    if str[0] == sep:                                         # ",1"
      parseFloatThousandSepRaise(0, sep, str)
    if pfLeadingDot notin options and str[0] == decimalDot:   # ".1"
      parseFloatThousandSepRaise(0, decimalDot, str)
    if str[^1] == sep:                                        # "1,"
      parseFloatThousandSepRaise(strLen, sep, str)
    if pfTrailingDot notin options and str[^1] == decimalDot: # "1."
      parseFloatThousandSepRaise(strLen, decimalDot, str)
    if pfSepAnywhere notin options and (str.len <= 4 and sep in str):
      parseFloatThousandSepRaise(0, sep, str)                 # "1,1"

    if (strLen == 3 or strLen == 4) and (
      (str[0] in {'i', 'I'} and str[1] in {'n', 'N'} and str[2] in {'f', 'F'}) or
      (str[0] in {'n', 'N'} and str[1] in {'a', 'A'} and str[2] in {'n', 'N'}) or
      (str[0] in {'+', '-'} and str[1] in {'i', 'I'} and str[2] in {'n', 'N'} and str[3] in {'f', 'F'}) or
      (str[0] in {'+', '-'} and str[1] in {'n', 'N'} and str[2] in {'a', 'A'} and str[3] in {'n', 'N'})):
      if pfNanInf notin options:
        parseFloatThousandSepRaise(0, sep, str)
      else:
        return parseFloat(str.join)  # Allow NaN, Inf, -Inf, +Inf

    var
      s = newStringOfCap(strLen)
      successive: int
      afterDot, lastWasDot, lastWasSep, hasAnySep, isNegative, hasAnyDot, isScientific: bool

    for idx, c in str:
      if c in '0' .. '9':  # Digits
        if hasAnySep and not afterDot and successive > 2:
          parseFloatThousandSepRaise(idx, c, str)
        else:
          s.add c
          lastWasSep = false
          lastWasDot = false
          inc successive
      elif c == sep:  # Thousands separator, this is NOT the dot
        if pfSepAnywhere notin options and (lastWasSep or afterDot) or
          (isNegative and idx == 1 or idx == 0) or isScientific:
          parseFloatThousandSepRaise(idx, c, str)
        else:
          lastWasSep = true # Do NOT add the Thousands separator here.
          hasAnySep = true
          successive = 0
      elif c == decimalDot:  # This is the dot
        if (not afterDot and not hasAnyDot and not lastWasDot) and
          (pfLeadingDot notin options and (isNegative and idx == 1 or idx == 0)) or
          (hasAnySep and pfSepAnywhere notin options and successive != 3): # Disallow .1
          parseFloatThousandSepRaise(idx, c, str)
        else:
          s.add '.' # Replace decimalDot to '.' so parseFloat can take it.
          successive = 0
          lastWasDot = true
          afterDot = true
          hasAnyDot = true
      elif c == '-':  # Allow negative float
        if isNegative or idx != 0 and not isScientific: # Disallow ---1.0
          parseFloatThousandSepRaise(idx, c, str)       # Allow 1.0e-9
        else:
          s.add '-'
          if idx == 0: # Allow 1.0e-9
            isNegative = true
      elif c in {'e', 'E'}:   # Allow scientific notation
        if isScientific:
          parseFloatThousandSepRaise(idx, c, str)
        else:
          s.add 'e'
          isScientific = true

    if pfDotOptional notin options and not hasAnyDot:
      parseFloatThousandSepRaise(0, sep, str)
    result = parseFloat(s)
