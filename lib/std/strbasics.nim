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
    assert a.dup(setSlice(0 .. 0)) == "H"
    assert a.dup(setSlice(0 .. 1)) == "He"
    assert a.dup(setSlice(0 .. 10)) == a
    assert a.dup(setSlice(1 .. 0)).len == 0
    assert a.dup(setSlice(20 .. -1)).len == 0


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

proc isLowerAscii*(c: char): bool {.inline.} =
  ## Checks whether or not `c` is a lower case character.
  runnableExamples:
    assert isLowerAscii('e') == true
    assert isLowerAscii('E') == false
    assert isLowerAscii('7') == false
  c in {'a'..'z'}

proc isUpperAscii*(c: char): bool {.inline.} =
  ## Checks whether or not `c` is an upper case character.
  runnableExamples:
    assert isUpperAscii('e') == false
    assert isUpperAscii('E') == true
    assert isUpperAscii('7') == false
  c in {'A'..'Z'}

proc toLowerAscii*(a: var string) {.inline.} =
  ## Optimized and inplace overload of `strutils.toLowerAscii`.
  runnableExamples:
    import std/sugar

    var x = "FooBar!"
    assert x.dup(toLowerAscii) == "foobar!"
  # refs https://github.com/timotheecour/Nim/pull/54
  # this is 10X faster than a naive implementation using a an optimization trick
  # that can be adapted in similar contexts. Predictable writes avoid write
  # hazards and lead to better machine code, compared to random writes arising
  # from: `if c.isUpperAscii: c = ...`
  for c in mitems(a):
    c = chr(c.ord + (if c.isUpperAscii: (ord('a') - ord('A')) else: 0))

proc toUpperAscii*(a: var string) {.inline.} =
  ## Optimized and inplace overload of `strutils.toLowerAscii`.
  # from: `if c.isUpperAscii: c = ...`
  runnableExamples:
    import std/sugar

    var x = "FooBar!"
    assert x.dup(toUpperAscii) == "FOOBAR!"
  for c in mitems(a):
    c = chr(c.ord - (if c.isLowerAscii: (ord('a') - ord('A')) else: 0))

when not defined(js):
  proc dataPointer[T](a: T): pointer =
    ## The Same as C++ `data` that works with std::string, std::vector etc.
    ## 
    ## .. note:: It is safe to use when a.len == 0 but whether the result is nil or not
    ##   is implementation defined for performance reasons.
    ## 
    # this could be improved with ocmpiler support to avoid the `if`, e.g. in C++
    # `&a[0]` is well defined even if a.size() == 0
    when T is string | seq:
      if a.len == 0: nil else: cast[pointer](a[0].unsafeAddr)
    elif T is array:
      when a.len > 0: a.unsafeAddr
      else: nil
    elif T is cstring:
      cast[pointer](a)
    else: static: assert false, $T

  proc setLen(result: var string, n: int, isInit: bool) =
    ## When isInit = false, elements are left uninitialized, analog to `{.noinit.}`
    ## else, there are 0-initialized.
    # xxx placeholder until system.setLen supports this
    # to distinguish between algorithms that need 0-initialization vs not; note
    # that `setLen` for string is inconsistent with `setLen` for seq.
    # likwise with `newString` vs `newSeq`. This should be fixed in `system`.
    let n0 = result.len
    result.setLen(n)
    if isInit and n > n0:
      zeroMem(result[n0].addr, n - n0)

proc forceCopy*(result: var string, a: string) =
  ## Always forces a copy no matter whether `a` is shallow.
  # the naitve `result = a` would not work if `a` is shallow
  template impl =
    let n = a.len
    result.setLen n
    for i in 0..<n:
      result[i] = a[i]

  when nimvm:
    impl
  else:
    when defined(js):
      impl
    else:
      let n = a.len
      result.setLen n, isInit = false
      copyMem(result.dataPointer, a.dataPointer, n)
