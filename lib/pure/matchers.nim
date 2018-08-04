#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains various string matchers for email addresses, etc.
##
## **Warning:** This module is deprecated since version 0.14.0.
{.deprecated.}

{.deadCodeElim: on.}  # dce option deprecated

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

include "system/inclrtl"

import parseutils, strutils

proc validEmailAddress*(s: string): bool {.noSideEffect,
  rtl, extern: "nsuValidEmailAddress".} =
  ## returns true if `s` seems to be a valid e-mail address.
  ## The checking also uses a domain list.
  const
    chars = Letters + Digits + {'!','#','$','%','&',
      '\'','*','+','/','=','?','^','_','`','{','}','|','~','-','.'}
  var i = 0
  if i >= s.len or s[i] notin chars or s[i] == '.': return false
  while i < s.len and s[i] in chars:
    if i+1 < s.len and s[i] == '.' and s[i+1] == '.': return false
    inc(i)
  if i >= s.len or s[i] != '@': return false
  var j = len(s)-1
  if j >= 0 and s[j] notin Letters: return false
  while j >= i and s[j] in Letters: dec(j)
  inc(i) # skip '@'
  while i < s.len and s[i] in {'0'..'9', 'a'..'z', '-', '.'}: inc(i)
  if i != s.len: return false

  var x = substr(s, j+1)
  if len(x) == 2 and x[0] in Letters and x[1] in Letters: return true
  case toLowerAscii(x)
  of "com", "org", "net", "gov", "mil", "biz", "info", "mobi", "name",
     "aero", "jobs", "museum": return true
  else: return false

proc parseInt*(s: string, value: var int, validRange: HSlice[int, int]) {.
  noSideEffect, rtl, extern: "nmatchParseInt".} =
  ## parses `s` into an integer in the range `validRange`. If successful,
  ## `value` is modified to contain the result. Otherwise no exception is
  ## raised and `value` is not touched; this way a reasonable default value
  ## won't be overwritten.
  var x = value
  try:
    discard parseutils.parseInt(s, x, 0)
  except OverflowError:
    discard
  if x in validRange: value = x

when isMainModule:
  doAssert "wuseldusel@codehome.com".validEmailAddress

{.pop.}

