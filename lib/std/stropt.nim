#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc strip*(s: var string, leading = true, trailing = true,
                   chars: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}) =
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

  template impl = 
    for index in first .. last:
      s[index - first] = s[index]

  var
    first = 0
    last = high(s)
  if leading:
    while first <= last and s[first] in chars: inc(first)
  if trailing:
    while last >= 0 and s[last] in chars: dec(last)

  if first > last:
    s.setLen(0)
    return

  if first > 0:
    when nimvm: impl()
    else:
      # not JS and not Nimscript
      when not declared(moveMem):
        impl()
      else:
        moveMem(addr s[0], addr s[first], last - first + 1)

  s.setLen(last - first + 1)
