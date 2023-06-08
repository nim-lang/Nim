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

proc parseTaggedVersions*(outp: string): seq[(string, Version)] =
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
        result.add (line.substr(0, commitEnd-1), v)
  result.sort proc (a, b: (string, Version)): int =
    (if a[1] < b[1]: 1
    elif a[1] == b[1]: 0
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

proc selectBestCommitMinVer*(data: openArray[(string, Version)]; elem: VersionInterval): string =
  for i in countdown(data.len-1, 0):
    if elem.matches(data[i][1]):
      return data[i][0]
  return ""

proc selectBestCommitMaxVer*(data: openArray[(string, Version)]; elem: VersionInterval): string =
  for i in countup(0, data.len-1):
    if elem.matches(data[i][1]): return data[i][0]
  return ""

proc toSemVer*(i: VersionInterval): VersionInterval =
  result = i
  if not result.isInterval and result.a.r in {verGe, verGt}:
    var major = 0
    let l1 = parseSaturatedNatural(result.a.v.string, major, 0)
    if l1 > 0:
      result.isInterval = true
      result.b = VersionReq(r: verLt, v: Version($(major+1)))

proc selectBestCommitSemVer*(data: openArray[(string, Version)]; elem: VersionInterval): string =
  result = selectBestCommitMaxVer(data, elem.toSemVer)

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

  const lines = """
24870f48c40da2146ce12ff1e675e6e7b9748355 1.6.12
b54236aaee2fc90200cb3a4e7070820ced9ce605 1.6.10
f06dc8ee3baf8f64cce67a28a6e6e8a8cd9bf04b 1.6.8
2f85924354af35278a801079b7ff3f8805ff1f5a 1.6.6
007bf1cb52eac412bc88b3ca2283127ad578ec04 1.6.4
ee18eda86eef2db0a49788bf0fc8e35996ba7f0d 1.6.2
1a2a82e94269741b0d8ba012994dd85a53f36f2d 1.6.0
074f7159752b0da5306bdedb3a4e0470af1f85c0 1.4.8
4eb05ebab2b4d8b0cd00b19a72af35a2d767819a 1.4.6
944c8e6d04a044611ed723391272f3c86781eadd 1.4.4
cd090a6151b452b99d65c5173400d4685916f970 1.4.2
01dd8c7a959adac4aa4d73abdf62cbc53ffed11b 1.4.0
1420d508dc4a3e51137647926d4db2f3fa62f43c 1.2.18
726e3bb1ffc6bacfaab0a0abf0209640acbac807 1.2.16
80d2206e68cd74020f61e23065c7a22376af8de5 1.2.14
ddfe3905964fe3db33d7798c6c6c4a493cbda6a3 1.2.12
6d914b7e6edc29c3b8ab8c0e255bd3622bc58bba 1.2.10
0d1a9f5933eab686ab3b527b36d0cebd3949a503 1.2.8
a5a0a9e3cb14e79d572ba377b6116053fc621f6d 1.2.6
f9829089b36806ac0129c421bf601cbb30c2842c 1.2.4
8b03d39fd387f6a59c97c2acdec2518f0b18a230 1.2.2
a8a4725850c443158f9cab38eae3e54a78a523fb 1.2.0
8b5888e0545ee3d931b7dd45d15a1d8f3d6426ef 1.0.10
7282e53cad6664d09e8c9efd0d7f263521eda238 1.0.8
283a4137b6868f1c5bbf0dd9c36d850d086fa007 1.0.6
e826ff9b48af376fdc65ba22f7aa1c56dc169b94 1.0.4
4c33037ef9d01905130b22a37ddb13748e27bb7c 1.0.2
0b6866c0dc48b5ba06a4ce57758932fbc71fe4c2 1.0.0
a202715d182ce6c47e19b3202e0c4011bece65d8 0.20.2
8ea451196bd8d77b3592b8b34e7a2c49eed784c9 0.20.0
1b512cc259b262d06143c4b34d20ebe220d7fb5c 0.19.6
be22a1f4e04b0fec14f7a668cbaf4e6d0be313cb 0.19.4
5cbc7f6322de8460cc4d395ed0df6486ae68004e 0.19.2
79934561e8dde609332239fbc8b410633e490c61 0.19.0
9c53787087e36b1c38ffd670a077903640d988a8 0.18.0
a713ffd346c376cc30f8cc13efaee7be1b8dfab9 0.17.2
2084650f7bf6f0db6003920f085e1a86f1ea2d11 0.17.0
f7f68de78e9f286b704304836ed8f20d65acc906 0.16.0
48bd4d72c45f0f0202a0ab5ad9d851b05d363988 0.15.2
dbee7d55bc107b2624ecb6acde7cabe4cb3f5de4 0.15.0
0a4854a0b7bcef184f060632f756f83454e9f9de 0.14.2
5333f2e4cb073f9102f30aacc7b894c279393318 0.14.0
7e50c5b56d5b5b7b96e56b6c7ab5e104124ae81b 0.13.0
49bce0ebe941aafe19314438fb724c081ae891aa 0.12.0
70789ef9c8c4a0541ba24927f2d99e106a6fe6cc 0.11.2
79cc0cc6e501c8984aeb5b217a274877ec5726bc 0.11.0
46d829f65086b487c08d522b8d0d3ad36f9a2197 0.10.2
9354d3de2e1ecc1747d6c42fbfa209fb824837c0 0.9.6
6bf5b3d78c97ce4212e2dd4cf827d40800650c48 0.9.4
220d35d9e19b0eae9e7cd1f1cac6e77e798dbc72 0.9.2
7a70058005c6c76c92addd5fc21b9706717c75e3 0.9.0
32b4192b3f0771af11e9d850046e5f3dd42a9a5f 0.8.14
"""

  proc p(s: string): VersionInterval =
    var err = false
    result = parseVersionInterval(s, 0, err)
    assert not err

  let tags = parseTaggedVersions(lines)
  let query = p">= 1.2 & < 1.4"
  assert selectBestCommitMinVer(tags, query) == "a8a4725850c443158f9cab38eae3e54a78a523fb"

  let query2 = p">= 1.2 & < 1.4"
  assert selectBestCommitMaxVer(tags, query2) == "1420d508dc4a3e51137647926d4db2f3fa62f43c"

  let query3 = p">= 0.20.0"
  assert selectBestCommitSemVer(tags, query3) == "a202715d182ce6c47e19b3202e0c4011bece65d8"

  let query4 = p"#head"
  assert selectBestCommitSemVer(tags, query4) == "24870f48c40da2146ce12ff1e675e6e7b9748355"
