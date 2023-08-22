#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [strutils, parseutils, algorithm]

type
  Version* = distinct string

  VersionRelation* = enum
    verGe, # >= V -- Equal or later
    verGt, # > V
    verLe, # <= V -- Equal or earlier
    verLt, # < V
    verEq, # V
    verAny, # *
    verSpecial # #head

  VersionReq* = object
    r: VersionRelation
    v: Version

  VersionInterval* = object
    a: VersionReq
    b: VersionReq
    isInterval: bool

template versionKey*(i: VersionInterval): string = i.a.v.string

proc createQueryEq*(v: Version): VersionInterval =
  VersionInterval(a: VersionReq(r: verEq, v: v))

proc extractGeQuery*(i: VersionInterval): Version =
  if i.a.r in {verGe, verGt, verEq}:
    result = i.a.v
  else:
    result = Version""

proc `$`*(v: Version): string {.borrow.}

proc isSpecial(v: Version): bool {.inline.} =
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

proc eq(a, b: string): bool {.inline.} =
  var i = 0
  var j = 0
  while i < a.len or j < b.len:
    var x = 0
    let l1 = parseSaturatedNatural(a, x, i)

    var y = 0
    let l2 = parseSaturatedNatural(b, y, j)

    if x == y:
      discard "continue"
    else:
      return false
    next l1, i, a
    next l2, j, b

  result = true

proc `==`*(a, b: Version): bool =
  if a.isSpecial or b.isSpecial:
    result = a.string == b.string
  else:
    result = eq(a.string, b.string)

proc parseVer(s: string; start: var int): Version =
  if start < s.len and s[start] == '#':
    var i = start
    while i < s.len and s[i] notin Whitespace: inc i
    result = Version s.substr(start, i-1)
    start = i
  elif start < s.len and s[start] in Digits:
    var i = start
    while i < s.len and s[i] in Digits+{'.'}: inc i
    result = Version s.substr(start, i-1)
    start = i
  else:
    result = Version""

proc parseVersion*(s: string; start: int): Version =
  var i = start
  while i < s.len and s[i] in Whitespace: inc i
  if i < s.len and s[i] == 'v': inc i
  result = parseVer(s, i)

proc parseSuffix(s: string; start: int; result: var VersionInterval; err: var bool) =
  # >= 1.5 & <= 1.8
  #        ^ we are here
  var i = start
  while i < s.len and s[i] in Whitespace: inc i
  # Nimble doesn't use the syntax `>= 1.5, < 1.6` but we do:
  if i < s.len and s[i] in {'&', ','}:
    inc i
    while i < s.len and s[i] in Whitespace: inc i
    if s[i] == '<':
      inc i
      var r = verLt
      if s[i] == '=':
        inc i
        r = verLe
      while i < s.len and s[i] in Whitespace: inc i
      result.b = VersionReq(r: r, v: parseVer(s, i))
      result.isInterval = true
      while i < s.len and s[i] in Whitespace: inc i
      # we must have parsed everything:
      if i < s.len:
        err = true

proc parseVersionInterval*(s: string; start: int; err: var bool): VersionInterval =
  var i = start
  while i < s.len and s[i] in Whitespace: inc i
  result = VersionInterval(a: VersionReq(r: verAny, v: Version""))
  if i < s.len:
    case s[i]
    of '*': result = VersionInterval(a: VersionReq(r: verAny, v: Version""))
    of '#', '0'..'9':
      result = VersionInterval(a: VersionReq(r: verEq, v: parseVer(s, i)))
      if result.a.v.isHead: result.a.r = verAny
      err = i < s.len
    of '=':
      inc i
      if i < s.len and s[i] == '=': inc i
      while i < s.len and s[i] in Whitespace: inc i
      result = VersionInterval(a: VersionReq(r: verEq, v: parseVer(s, i)))
      err = i < s.len
    of '<':
      inc i
      var r = verLt
      if i < s.len and s[i] == '=':
        r = verLe
        inc i
      while i < s.len and s[i] in Whitespace: inc i
      result = VersionInterval(a: VersionReq(r: r, v: parseVer(s, i)))
      parseSuffix(s, i, result, err)
    of '>':
      inc i
      var r = verGt
      if i < s.len and s[i] == '=':
        r = verGe
        inc i
      while i < s.len and s[i] in Whitespace: inc i
      result = VersionInterval(a: VersionReq(r: r, v: parseVer(s, i)))
      parseSuffix(s, i, result, err)
    else:
      err = true
  else:
    result = VersionInterval(a: VersionReq(r: verAny, v: Version"#head"))

type
  Commit* = object
    h*: string
    v*: Version

proc parseTaggedVersions*(outp: string): seq[Commit] =
  result = @[]
  for line in splitLines(outp):
    if not line.endsWith("^{}"):
      var i = 0
      while i < line.len and line[i] notin Whitespace: inc i
      let commitEnd = i
      while i < line.len and line[i] in Whitespace: inc i
      while i < line.len and line[i] notin Digits: inc i
      let v = parseVersion(line, i)
      if v != Version(""):
        result.add Commit(h: line.substr(0, commitEnd-1), v: v)
  result.sort proc (a, b: Commit): int =
    (if a.v < b.v: 1
    elif a.v == b.v: 0
    else: -1)

proc matches(pattern: VersionReq; v: Version): bool =
  case pattern.r
  of verGe:
    result = pattern.v < v or pattern.v == v
  of verGt:
    result = pattern.v < v
  of verLe:
    result = v < pattern.v or pattern.v == v
  of verLt:
    result = v < pattern.v
  of verEq, verSpecial:
    result = pattern.v == v
  of verAny:
    result = true

proc matches*(pattern: VersionInterval; v: Version): bool =
  if pattern.isInterval:
    result = matches(pattern.a, v) and matches(pattern.b, v)
  else:
    result = matches(pattern.a, v)

const
  MinCommitLen = len("#baca3")

proc extractSpecificCommit*(pattern: VersionInterval): string =
  if not pattern.isInterval and pattern.a.r == verEq and pattern.a.v.isSpecial and pattern.a.v.string.len >= MinCommitLen:
    result = pattern.a.v.string.substr(1)
  else:
    result = ""

proc matches*(pattern: VersionInterval; x: Commit): bool =
  if pattern.isInterval:
    result = matches(pattern.a, x.v) and matches(pattern.b, x.v)
  elif pattern.a.r == verEq and pattern.a.v.isSpecial and pattern.a.v.string.len >= MinCommitLen:
    result = x.h.startsWith(pattern.a.v.string.substr(1))
  else:
    result = matches(pattern.a, x.v)

proc selectBestCommitMinVer*(data: openArray[Commit]; elem: VersionInterval): string =
  for i in countdown(data.len-1, 0):
    if elem.matches(data[i]):
      return data[i].h
  return ""

proc selectBestCommitMaxVer*(data: openArray[Commit]; elem: VersionInterval): string =
  for i in countup(0, data.len-1):
    if elem.matches(data[i]): return data[i].h
  return ""

proc toSemVer*(i: VersionInterval): VersionInterval =
  result = i
  if not result.isInterval and result.a.r in {verGe, verGt}:
    var major = 0
    let l1 = parseSaturatedNatural(result.a.v.string, major, 0)
    if l1 > 0:
      result.isInterval = true
      result.b = VersionReq(r: verLt, v: Version($(major+1)))

proc selectBestCommitSemVer*(data: openArray[Commit]; elem: VersionInterval): string =
  result = selectBestCommitMaxVer(data, elem.toSemVer)
