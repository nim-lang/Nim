#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module supports helper routines for working with ``cstring``
## without having to convert ``cstring`` to ``string`` in order to
## save allocations.

include "system/inclrtl"

proc toLowerAscii(c: char): char {.inline.} =
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

when defined(js):
  proc startsWith*(s, prefix: cstring): bool {.noSideEffect,
    importjs: "#.startsWith(#)".}

  proc endsWith*(s, suffix: cstring): bool {.noSideEffect,
    importjs: "#.endsWith(#)".}
  
  # JS string has more operations that might warrant its own module:
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String
else:
  proc startsWith*(s, prefix: cstring): bool {.noSideEffect,
    rtl, extern: "csuStartsWith".} =
    ## Returns true if ``s`` starts with ``prefix``.
    ##
    ## If ``prefix == ""`` true is returned.
    ## 
    ## JS backend uses native ``String.prototype.startsWith``.
    var i = 0
    while true:
      if prefix[i] == '\0': return true
      if s[i] != prefix[i]: return false
      inc(i)

  proc endsWith*(s, suffix: cstring): bool {.noSideEffect,
    rtl, extern: "csuEndsWith".} =
    ## Returns true if ``s`` ends with ``suffix``.
    ##
    ## If ``suffix == ""`` true is returned.
    ## 
    ## JS backend uses native ``String.prototype.endsWith``.
    let slen = s.len
    var i = 0
    var j = slen - len(suffix)
    while i+j <% slen:
      if s[i+j] != suffix[i]: return false
      inc(i)
    if suffix[i] == '\0': return true

proc cmpIgnoreStyle*(a, b: cstring): int {.noSideEffect,
  rtl, extern: "csuCmpIgnoreStyle".} =
  ## Semantically the same as ``cmp(normalize($a), normalize($b))``. It
  ## is just optimized to not allocate temporary strings.  This should
  ## NOT be used to compare Nim identifier names. use `macros.eqIdent`
  ## for that.  Returns:
  ##
  ## | 0 if a == b
  ## | < 0 if a < b
  ## | > 0 if a > b
  ## 
  ## Not supported for JS backend, use `strutils.cmpIgnoreStyle
  ## <strutils.html#cmpIgnoreStyle%2Cstring%2Cstring>`_ instead.
  var i = 0
  var j = 0
  while true:
    while a[i] == '_': inc(i)
    while b[j] == '_': inc(j) # BUGFIX: typo
    var aa = toLowerAscii(a[i])
    var bb = toLowerAscii(b[j])
    result = ord(aa) - ord(bb)
    if result != 0 or aa == '\0': break
    inc(i)
    inc(j)

proc cmpIgnoreCase*(a, b: cstring): int {.noSideEffect,
  rtl, extern: "csuCmpIgnoreCase".} =
  ## Compares two strings in a case insensitive manner. Returns:
  ##
  ## | 0 if a == b
  ## | < 0 if a < b
  ## | > 0 if a > b
  ## 
  ## Not supported for JS backend, use `strutils.cmpIgnoreCase
  ## <strutils.html#cmpIgnoreCase%2Cstring%2Cstring>`_ instead.
  var i = 0
  while true:
    var aa = toLowerAscii(a[i])
    var bb = toLowerAscii(b[i])
    result = ord(aa) - ord(bb)
    if result != 0 or aa == '\0': break
    inc(i)
