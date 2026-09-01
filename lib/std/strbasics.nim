#
#
#              Nim's Runtime Library
#        (c) Copyright 2021 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides some high performance string operations.
##
## Experimental API, subject to change.

when defined(nimPreviewSlimSystem):
  import std/assertions


const whitespaces = {' ', '\t', '\v', '\r', '\l', '\f'}

const notJSnotNims = not defined(js) and not defined(nimscript)
template whenNotVmJsNims(normalBody, restrictedBody: untyped) =
  ## hack, see: #12517 #12518; Edit together with identical in `system`
  when nimvm:
    restrictedBody
  else:
    when notJSnotNims:
      normalBody
    else:
      restrictedBody

proc add*(x: var string, y: openArray[char]) =
  ## Concatenates `x` and `y` in place. `y` must not overlap with `x`
  # Use `{.noalias.}` ?
  if y.len == 0: return
  let oldLen = x.len
  x.setLenUninit(oldLen + y.len)
  whenNotVmJsNims():
    {.cast(noSideEffect).}:
      copyMem(beginStore(x, oldLen + y.len, oldLen), addr(y[0]), y.len)
      endStore(x)
  do:
    for i, ch in y:
      x[oldLen + i] = ch

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
    doAssert a.dup(setSlice(7 .. 9)) == "Nim"
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
  if first > 0:
    whenNotVmJsNims():
      let p = beginStore(s, s.len)
      moveMem(p, addr p[first], last - first + 1)
      endStore(s)
    do:
      for index in first .. last:
        s[index - first] = s[index]
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
