#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

from strutils import toLowerAscii

type
  PrefixMatch* {.pure.} = enum
    None,   ## no prefix detected
    Abbrev  ## prefix is an abbreviation of the symbol
    Substr, ## prefix is a substring of the symbol
    Prefix, ## prefix does match the symbol

proc prefixMatch*(p, s: string): PrefixMatch =
  template eq(a, b): bool = a.toLowerAscii == b.toLowerAscii
  if p.len > s.len: return PrefixMatch.None
  var i = 0
  let L = s.len
  # check for prefix/contains:
  while i < L:
    if s[i] == '_': inc i
    if i < L and eq(s[i], p[0]):
      var ii = i+1
      var jj = 1
      while ii < L and jj < p.len:
        if p[jj] == '_': inc jj
        if s[ii] == '_': inc ii
        if not eq(s[ii], p[jj]): break
        inc ii
        inc jj

      if jj >= p.len:
        if i == 0: return PrefixMatch.Prefix
        else: return PrefixMatch.Substr
    inc i
  # check for abbrev:
  if eq(s[0], p[0]):
    i = 1
    var j = 1
    while i < s.len:
      if i < s.len-1 and s[i] == '_':
        if j < p.len and eq(p[j], s[i+1]): inc j
        else: return PrefixMatch.None
      if i < s.len and s[i] in {'A'..'Z'} and s[i-1] notin {'A'..'Z'}:
        if j < p.len and eq(p[j], s[i]): inc j
        else: return PrefixMatch.None
      inc i
    if j >= p.len:
      return PrefixMatch.Abbrev
    else:
      return PrefixMatch.None
  return PrefixMatch.None

when isMainModule:
  import macros

  macro check(val, body: untyped): untyped =
    result = newStmtList()
    expectKind body, nnkStmtList
    for b in body:
      expectKind b, nnkPar
      expectLen b, 2
      let p = b[0]
      let s = b[1]
      result.add quote do:
        echo prefixMatch(`p`, `s`) == `val`

  check PrefixMatch.Prefix:
    ("abc", "abc")
    ("a", "abc")
    ("xyz", "X_yzzzZe")

  check PrefixMatch.Substr:
    ("b", "abc")
    ("abc", "fooabcabc")
    ("abC", "foo_AB_c")

  check PrefixMatch.Abbrev:
    ("abc", "AxxxBxxxCxxx")
    ("xyz", "X_yabcZe")

  check PrefixMatch.None:
    ("foobar", "afkslfjd_as")
    ("xyz", "X_yuuZuuZe")
    ("ru", "remotes")
