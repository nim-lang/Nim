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
import std/private/since
import strutils

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


proc wordsToCap*(wordCount: Positive; threshold = 80.Positive): int {.since: (1, 5).} =
  ## Returns an "approximation" of `string` capacity from a `wordCount` with an optional `threshold`,
  ## using the average length of words world-wide, like a cache you hit *the happy path* frequently.
  ## This is useful for optimizations with `newStringOfCap` and `newString`.
  ##
  ## Average length of words:
  ## * World `9`, English `6` (Wikipedia, Wolfram, Oxford, etc).
  ## * There are shorter and longer words but this is the most frequently used words.
  ## * Define a customized average length of words by defining `nimAverageWordLength`.
  ## * See http://ravi.io/language-word-lengths
  ##
  ## See also:
  ## * `newStringOfCap <system.html#newStringOfCap>`_
  ## * `newString <system.html#newString>`_
  runnableExamples:
    import strutils
    const sentence0 = "Hello World" ## Random sentences; You can try your own sentences...
    doAssert wordsToCap(wordCount = sentence0.split.len) >= sentence0.len
    const sentence1 = "The quick brown fox jumps over the lazy dog"
    doAssert wordsToCap(wordCount = sentence1.split.len) >= sentence1.len
    const sentence2 = "Nim is a statically typed compiled systems programming language."
    doAssert wordsToCap(wordCount = sentence2.split.len) >= sentence2.len
    const sentence3 = "She tore a hole in our universe, a gateway to another dimension, a dimension of pure chaos, pure evil"
    doAssert wordsToCap(wordCount = sentence3.split.len) >= sentence3.len
  # max((9 * wordCount) + (len(whitespace or newline) * wordCount), threshold)
  const nimAverageWordLength {.intdefine.}: Positive = 9
  result = max((nimAverageWordLength * wordCount) + wordCount , threshold) # Still better than a random hardcoded "guess".
