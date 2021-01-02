#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module supports helper routines for working with `cstring`
## without having to convert `cstring` to `string` in order to
## save allocations.

include "system/inclrtl"
import std/private/strimpl


when defined(js):
  func startsWith*(s, prefix: cstring): bool {.importjs: "#.startsWith(#)".}

  func endsWith*(s, suffix: cstring): bool {.importjs: "#.endsWith(#)".}

  func cmpIgnoreStyle*(a, b: cstring): int =
    cmpIgnoreStyleImpl(a, b)

  func cmpIgnoreCase*(a, b: cstring): int =
    cmpIgnoreCaseImpl(a, b)

  # JS string has more operations that might warrant its own module:
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String
else:
  func startsWith*(s, prefix: cstring): bool {.rtl, extern: "csuStartsWith".} =
    ## Returns true if `s` starts with `prefix`.
    ##
    ## If `prefix == ""` true is returned.
    ## 
    ## JS backend uses native `String.prototype.startsWith`.
    runnableExamples:
      assert startsWith(cstring"Hello, Nimion", cstring"Hello")
      assert not startsWith(cstring"Hello, Nimion", cstring"Nimion")

    var i = 0
    while true:
      if prefix[i] == '\0': return true
      if s[i] != prefix[i]: return false
      inc(i)

  func endsWith*(s, suffix: cstring): bool {.rtl, extern: "csuEndsWith".} =
    ## Returns true if `s` ends with `suffix`.
    ##
    ## If `suffix == ""` true is returned.
    ##
    ## JS backend uses native `String.prototype.endsWith`.
    runnableExamples:
      assert endsWith(cstring"Hello, Nimion", cstring"Nimion")
      assert not endsWith(cstring"Hello, Nimion", cstring"Hello")

    let slen = s.len
    var i = 0
    var j = slen - len(suffix)
    while i+j <% slen:
      if s[i+j] != suffix[i]: return false
      inc(i)
    if suffix[i] == '\0': return true

  func cmpIgnoreStyle*(a, b: cstring): int {.rtl, extern: "csuCmpIgnoreStyle".} =
    ## Semantically the same as `cmp(normalize($a), normalize($b))`. It
    ## is just optimized to not allocate temporary strings.  This should
    ## NOT be used to compare Nim identifier names. use `macros.eqIdent`
    ## for that. Returns:
    ##
    ## .. code-block::
    ##   0 if a == b
    ##   < 0 if a < b
    ##   > 0 if a > b
    runnableExamples:
      assert cmpIgnoreStyle(cstring"hello", cstring"H_e_L_Lo") == 0
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

  func cmpIgnoreCase*(a, b: cstring): int {.rtl, extern: "csuCmpIgnoreCase".} =
    ## Compares two strings in a case insensitive manner. Returns:
    ##
    ## .. code-block::
    ##   0 if a == b
    ##   < 0 if a < b
    ##   > 0 if a > b
    runnableExamples:
      assert cmpIgnoreCase(cstring"hello", cstring"HeLLo") == 0
      assert cmpIgnoreCase(cstring"echo", cstring"hello") < 0
      assert cmpIgnoreCase(cstring"yellow", cstring"hello") > 0

    var i = 0
    while true:
      var aa = toLowerAscii(a[i])
      var bb = toLowerAscii(b[i])
      result = ord(aa) - ord(bb)
      if result != 0 or aa == '\0': break
      inc(i)
