#
#
#           The Nim Compiler
#        (c) Copyright 2021 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides some high performance string operations.
##
## Experimental API, subject to change.

from algorithm import fill

const whitespaces = {' ', '\t', '\v', '\r', '\l', '\f'}

proc add*(x: var string, y: openArray[char]) =
  ## Concatenates `x` and `y` in place. `y` must not overlap with `x` to
  ## allow future `memcpy` optimizations.
  # Use `{.noalias.}` ?
  let n = x.len
  x.setLen n + y.len
    # pending https://github.com/nim-lang/Nim/issues/14655#issuecomment-643671397
    # use x.setLen(n + y.len, isInit = false)
  var i = 0
  while i < y.len:
    x[n + i] = y[i]
    i.inc
  # xxx use `nimCopyMem(x[n].addr, y[0].addr, y.len)` after some refactoring

func stripSlice(s: openArray[char], leading = true, trailing = true, chars: set[char] = whitespaces): Slice[int] =
  ## Returns the slice range of `s` which is stripped `chars`.
  runnableExamples:
    assert stripSlice(" abc  ") == 1 .. 3
  var
    first = 0
    last = high(s)
  if leading:
    while first <= last and s[first] in chars: inc(first)
  if trailing:
    while last >= first and s[last] in chars: dec(last)
  result = first .. last

func setSlice*(s: var string, slice: Slice[int]) =
  ## Inplace version of `substr`.
  runnableExamples:
    import std/sugar

    var a = "Hello, Nim!"
    doassert a.dup(setSlice(7 .. 9)) == "Nim"
    doAssert a.dup(setSlice(0 .. 0)) == "H"
    doAssert a.dup(setSlice(0 .. 1)) == "He"
    doAssert a.dup(setSlice(0 .. 10)) == a
    doAssert a.dup(setSlice(1 .. 0)).len == 0
    doAssert a.dup(setSlice(20 .. -1)).len == 0


    doAssertRaises(AssertionDefect):
      discard a.dup(setSlice(-1 .. 1))

    doAssertRaises(AssertionDefect):
      discard a.dup(setSlice(1 .. 11))


  let first = slice.a
  let last = slice.b

  assert first >= 0
  assert last <= s.high

  if first > last:
    s.setLen(0)
    return
  template impl =
    for index in first .. last:
      s[index - first] = s[index]
  if first > 0:
    when nimvm: impl()
    else:
      # not JS and not Nimscript
      when not declared(moveMem):
        impl()
      else:
        when defined(nimSeqsV2):
          prepareMutation(s)
        moveMem(addr s[0], addr s[first], last - first + 1)
  s.setLen(last - first + 1)

func strip*(a: var string, leading = true, trailing = true, chars: set[char] = whitespaces) {.inline.} =
  ## Inplace version of `strip`. Strips leading or
  ## trailing `chars` (default: whitespace characters).
  ##
  ## If `leading` is true (default), leading `chars` are stripped.
  ## If `trailing` is true (default), trailing `chars` are stripped.
  ## If both are false, the string is unchanged.
  runnableExamples:
    var a = "  vhellov   "
    strip(a)
    assert a == "vhellov"

    a = "  vhellov   "
    a.strip(leading = false)
    assert a == "  vhellov"

    a = "  vhellov   "
    a.strip(trailing = false)
    assert a == "vhellov   "

    var c = "blaXbla"
    c.strip(chars = {'b', 'a'})
    assert c == "laXbl"
    c = "blaXbla"
    c.strip(chars = {'b', 'a', 'l'})
    assert c == "X"

  setSlice(a, stripSlice(a, leading, trailing, chars))

func indexOfUsingBoyerMooreHorspool(
  haystack: openArray[char],
  needle: openArray[char]
): int =
  ## This is an implementation of the Boyer-Moore-Horspool algorithm
  ## https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm

  # Compute the lookup table
  var table {.noinit.}: array[char, int]
  fill(table, needle.len)
  for i in 0 ..< needle.len - 1:
    table[needle[i]] = needle.len - 1 - i

  var skip: int = 0
  let rightEndpoint: int = haystack.len - needle.len
  while skip <= rightEndpoint:
    var i: int = needle.high
    while haystack[skip + i] == needle[i]:
      if i == 0:
        return skip
      dec i
    skip += table[haystack[skip + needle.high]]
  return -1

when not (defined(js) or defined(nimdoc) or defined(nimscript)):
  func c_memchr(cstr: pointer, c: char, n: csize_t): pointer {.
                importc: "memchr", header: "<string.h>".}
  func c_strstr(haystack, needle: cstring): cstring {.
    importc: "strstr", header: "<string.h>".}

  const hasCStringBuiltin: bool = false
else:
  const hasCStringBuiltin: bool = false

func indexOf*(haystack: openArray[char], needle: char): int =
  ## Searches for the leftmost occurrence in `haystack` of `needle` and returns
  ## its index if it is found. Otherwise, returns -1. Note that this
  ## differs from
  ## `strutils.find <strutils.html#find,string,char,Natural,int>`_ in that
  ## `strutils.find` returns an index based on the start of the string, not the
  ## start of the slice.
  ##
  ## See also:
  ## * `deprecated strutils.find<strutils.html#find,string,char,Natural,int>`_
  runnableExamples:
    doAssert "abcabc".indexOf('b') == 1
    doAssert "abcdef".toOpenArray(3, 5).indexOf('e') == 1
    doAssert "abc".indexOf('z') == -1
  if haystack.len == 0:
    return -1
  when nimvm:
    return system.find(haystack, needle)
  else:
    when hasCStringBuiltin:
      let found = c_memchr(haystack[0].unsafeAddr, needle, csize_t(haystack.len))
      if not found.isNil:
        return cast[ByteAddress](found) -% cast[ByteAddress](haystack[0].unsafeAddr)
      else:
        return -1
    else:
      return system.find(haystack, needle)

func indexOf*(haystack: openArray[char], needles: set[char]): int =
  ## Searches for the leftmost character in `haystack` that is in `needles` and
  ## returns its index if it is found. Otherwise, returns -1. Note that this
  ## differs from
  ## `strutils.find <strutils.html#find,string,set[char],Natural,int>`_ in that
  ## `strutils.find` returns an index based on the start of the string, not the
  ## start of the slice.
  ##
  ## See also:
  ## * `deprecated strutils.find<strutils.html#find,string,set[char],Natural,int>`_
  runnableExamples:
    doAssert "abcabc".indexOf({'b', 'c', 'z'}) == 1
    doAssert "abcabc".toOpenArray(3, 5).indexOf({'c', 'z'}) == 2
    doAssert "abcabc".indexOf({'x'}) == -1
  for index in low(haystack) .. high(haystack):
    if haystack[index] in needles:
      return index
  return -1

func indexOf*(haystack: openArray[char], needle: openArray[char]): int =
  ## Searches for `needle` in `haystack`. Returns the leftmost index of `needle`
  ## if it is found. Otherwise, returns -1. Note that this differs from
  ## `strutils.find <strutils.html#find,string,string,Natural,int>`_ in that
  ## `strutils.find` returns an index based on the start of the string, not the
  ## start of the slice.
  ##
  ## See also:
  ## * `deprecated strutils.find<strutils.html#find,string,string,Natural,int>`_
  runnableExamples:
    doAssert "abcabc".indexOf("") == 0
    doAssert "abcabc".indexOf("a") == 0
    doAssert "abcabc".indexOf("bc") == 1
    doAssert "abcabc".toOpenArray(2, 5).indexOf("bc") == 2
    doAssert "abcabc".indexOf("z") == -1
  if needle.len == 0:
    return 0
  elif haystack.len < needle.len:
    return -1

  when not hasCStringBuiltin:
    result = indexOfUsingBoyerMooreHorspool(haystack, needle)
  else:
    when nimvm:
      result = indexOfUsingBoyerMooreHorspool(haystack, needle)
    else:
      when hasCStringBuiltin:
        if haystack.len > 0:
          let found = c_strstr(haystack[0].unsafeAddr, needle[0].unsafeAddr)
          if not found.isNil:
            result = cast[ByteAddress](found) -% cast[ByteAddress](haystack[0].unsafeAddr)

            if result > haystack.len - needle.len:
              # c_strstr will look all the way until a null byte is found, so
              # we must ensure that the return value is inside the
              # openArray-defined bounds of the strings
              result = -1
          else:
            result = -1
        else:
          result = indexOfUsingBoyerMooreHorspool(haystack, needle)
      else:
        result = indexOfUsingBoyerMooreHorspool(haystack, needle)
