#
#
#           The Nim Compiler
#        (c) Copyright 2021 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const whitespaces = {' ', '\t', '\v', '\r', '\l', '\f'}

func stripSlice*(s: openArray[char], leading = true, trailing = true, chars: set[char] = whitespaces): Slice[int] =
  runnableExamples:
    doAssert stripSlice(" abc  ") == 1 .. 3
  var
    first = 0
    last = high(s)
  if leading:
    while first <= last and s[first] in chars: inc(first)
  if trailing:
    while last >= first and s[last] in chars: dec(last)
  result = first .. last

func setSlice*(s: var string, slice: Slice[int]) =
  ## Inplace version for `substr`.
  let first = slice.a
  let last = slice.b
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
        moveMem(addr s[0], addr s[first], last - first + 1)
  s.setLen(last - first + 1)

func strip*(a: var string, leading = true, trailing = true, chars: set[char] = whitespaces) =
  ## Inplace version of `strip`. Strips leading or 
  ## trailing `chars` (default: whitespace characters).
  ##
  ## If `leading` is true (default), leading `chars` are stripped.
  ## If `trailing` is true (default), trailing `chars` are stripped.
  ## If both are false, the string is unchanged.
  runnableExamples:
    var a = "  vhellov   "
    strip(a)
    doAssert a == "vhellov"

    a = "  vhellov   "
    a.strip(leading = false)
    doAssert a == "  vhellov"

    a = "  vhellov   "
    a.strip(trailing = false)
    doAssert a == "vhellov   "

    var c = "blaXbla"
    c.strip(chars = {'b', 'a'})
    doAssert c == "laXbl"
    c = "blaXbla"
    c.strip(chars = {'b', 'a', 'l'})
    doAssert c == "X"

  setSlice(a, stripSlice(a, leading, trailing, chars))
