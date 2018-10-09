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

proc startsWith*(s, prefix: cstring): bool {.noSideEffect,
  rtl, extern: "csuStartsWith".} =
  ## Returns true iff ``s`` starts with ``prefix``.
  ##
  ## If ``prefix == ""`` true is returned.
  var i = 0
  while true:
    if prefix[i] == '\0': return true
    if s[i] != prefix[i]: return false
    inc(i)

proc endsWith*(s, suffix: cstring): bool {.noSideEffect,
  rtl, extern: "csuEndsWith".} =
  ## Returns true iff ``s`` ends with ``suffix``.
  ##
  ## If ``suffix == ""`` true is returned.
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
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b
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
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b
  var i = 0
  while true:
    var aa = toLowerAscii(a[i])
    var bb = toLowerAscii(b[i])
    result = ord(aa) - ord(bb)
    if result != 0 or aa == '\0': break
    inc(i)
