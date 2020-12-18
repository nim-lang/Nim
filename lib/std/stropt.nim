import std/strutils
import std/private/since


proc stripInplace*(s: var string, leading = true, trailing = true,
                   chars: set[char] = Whitespace) {.since: (1, 5, 1).} =
  ## Inplace version of `strip`. Strips leading or 
  ## trailing `chars` (default: whitespace characters).
  ##
  ## If `leading` is true (default), leading `chars` are stripped.
  ## If `trailing` is true (default), trailing `chars` are stripped.
  ## If both are false, the string is unchanged.
  ##
  ## See also:
  ## * `strip proc<#strip,string,set[char]>`_
  runnableExamples:
    var a = "  vhellov   "
    stripInplace(a)
    doAssert a == "vhellov"

    a = "  vhellov   "
    a.stripInplace(leading = false)
    doAssert a == "  vhellov"

    a = "  vhellov   "
    a.stripInplace(trailing = false)
    doAssert a == "vhellov   "

    var c = "blaXbla"
    c.stripInplace(chars = {'b', 'a'})
    doAssert c == "laXbl"
    c = "blaXbla"
    c.stripInplace(chars = {'b', 'a', 'l'})
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

  if first > 0:
    when nimvm: impl()
    else:
      # not JS and not Nimscript
      when not declared(moveMem):
        impl()
      else:
        moveMem(addr s[0], addr s[first], last - first + 1)

  s.setLen(last - first + 1)
