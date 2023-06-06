#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [strutils, parseutils]

type
  Version* = distinct string

proc `$`*(v: Version): string {.borrow.}

proc isSpecial(v: Version): bool =
  result = v.string.len > 0 and v.string[0] == '#'

proc isValidVersion*(v: string): bool {.inline.} =
  result = v.len > 0 and v[0] in {'#'} + Digits

proc isHead(v: Version): bool {.inline.} = cmpIgnoreCase(v.string, "#head") == 0

template next(l, p, s: untyped) =
  if l > 0:
    inc p, l
    if p < s.len and s[p] == '.':
      inc p
    else:
      p = s.len
  else:
    p = s.len

proc lt(a, b: string): bool {.inline.} =
  var i = 0
  var j = 0
  while i < a.len or j < b.len:
    var x = 0
    let l1 = parseSaturatedNatural(a, x, i)

    var y = 0
    let l2 = parseSaturatedNatural(b, y, j)

    if x < y:
      return true
    elif x == y:
      discard "continue"
    else:
      return false
    next l1, i, a
    next l2, j, b

  result = false

proc `<`*(a, b: Version): bool =
  # Handling for special versions such as "#head" or "#branch".
  if a.isSpecial or b.isSpecial:
    if a.isHead: return false
    if b.isHead: return true
    # any order will do as long as the "sort" operation moves #thing
    # to the bottom:
    if a.isSpecial and b.isSpecial:
      return a.string < b.string
  return lt(a.string, b.string)

proc `==`*(a, b: Version): bool {.borrow.}

proc parseVersion*(s: string; start: int): Version =
  if start < s.len and s[start] == '#':
    var i = start
    while i < s.len and s[i] notin Whitespace: inc i
    result = Version s.substr(start, i-1)
  elif start < s.len and s[start] in Digits:
    var i = start
    while i < s.len and s[i] in Digits+{'.'}: inc i
    result = Version s.substr(start, i-1)
  else:
    result = Version""

when isMainModule:
  template v(x): untyped = Version(x)

  assert v"1.0" < v"1.0.1"
  assert v"1.0" < v"1.1"
  assert v"1.2.3" < v"1.2.4"
  assert v"2.0.0" < v"2.0.0.1"
  assert v"2.0.0" < v"20.0"
  assert not (v"1.10.0" < v"1.2.0")
  assert v"1.0" < v"#head"
  assert v"#branch" < v"#head"
  assert v"#branch" < v"1.0"
  assert not (v"#head" < v"#head")
  assert not (v"#head" < v"10.0")
