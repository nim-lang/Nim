#
#            Nim's Runtime Library
#        (c) Copyright 2026 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std/[options, tables]
import regex, regex/nfatype

export options
export regex.RegexFlags, regex.RegexError

type
  Regex* = regex.Regex2
  RegexMatch* = object
    str*: string
    matchImpl: regex.RegexMatch2

  Captures* {.borrow: `.`.} = distinct RegexMatch
  CaptureBounds* {.borrow: `.`.} = distinct RegexMatch

func captureCount*(pattern: Regex): int =
  pattern.toRegex().groupsCount

func captureNameId*(pattern: Regex): Table[string, int] =
  for k, v in pattern.toRegex().namedGroups:
    result[k] = v

func captureBounds*(match: RegexMatch): CaptureBounds {.inline.} =
  CaptureBounds(match)

func captures*(match: RegexMatch): Captures {.inline.} =
  Captures(match)

func contains*(match: Captures or CaptureBounds, i: int): bool {.inline.} =
  i >= -1 and i < match.matchImpl.groupsCount and match.matchImpl.group(i) != reNonCapture

func len*(match: Captures or CaptureBounds): int {.inline.} =
  match.matchImpl.groupsCount

func `[]`*(match: CaptureBounds; i: int): HSlice[int, int] {.inline.} =
  if i == -1: match.matchImpl.boundaries else: match.matchImpl.group(i)

func `[]`*(match: CaptureBounds; name: string): HSlice[int, int] {.inline.} =
  result = match.matchImpl.group(name)
  if result == reNonCapture:
    raise newException(KeyError, "Group '" & name & "' was not captured")

func `[]`*(match: Captures; i: int): string {.inline.} =
  match.str[CaptureBounds(match)[i]]

func `[]`*(match: Captures, name: string): string {.inline.} =
  match.str[CaptureBounds(match)[name]]

func match*(match: RegexMatch): string {.inline.} =
  match.str[match.matchImpl.boundaries]

func matchBounds*(match: RegexMatch): HSlice[int, int] {.inline.} =
  match.matchImpl.boundaries

func contains*(match: CaptureBounds or Captures, name: string): bool {.inline.} =
  name in match.matchImpl.namedGroups and
  match.matchImpl.group(name) != reNonCapture

func toTable*(match: Captures): Table[string, string] =
  result = initTable[string, string]()
  for k, i in match.matchImpl.namedGroups:
    let r = match.matchImpl.group(i)
    if r != reNonCapture:
      result[k] = match.str[r]

func toTable*(match: CaptureBounds): Table[string, HSlice[int, int]] =
  result = initTable[string, HSlice[int, int]]()
  for k, i in match.matchImpl.namedGroups:
    let r = match.matchImpl.group(i)
    if r != reNonCapture:
      result[k] = match.matchImpl.group(i)

iterator items*(match: CaptureBounds; default = none(HSlice[int, int])): Option[HSlice[int, int]] =
  for i in 0 ..< match.len:
    yield if i in match: some(match[i]) else: default

iterator items*(match: Captures; default = none(string)): Option[string] =
  for i in 0 ..< match.len:
    yield if i in match: some(match[i]) else: default

func toSeq*(match: CaptureBounds;
            default = none(HSlice[int, int])): seq[Option[HSlice[int, int]]] =
  result = @[]
  for it in match.items(default): result.add it

func toSeq*(match: Captures;
            default: Option[string] = none(string)): seq[Option[string]] =
  result = @[]
  for it in match.items(default): result.add it

func `$`*(match: RegexMatch): string =
  match.match

func re*(pattern: static string; flags: static RegexFlags = {}): static[Regex2] =
  result = regex.re2(pattern, flags)

func re*(pattern: string; flags: RegexFlags = {}): Regex =
  result = regex.re2(pattern, flags)

func match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  var mat = default(RegexMatch)
  let r = regex.startsWith(str.toOpenArray(0, min(str.high, endpos)), pattern, mat.matchImpl, start)
  if r:
    mat.str = str
    some(mat)
  else:
    none(RegexMatch)

iterator findIter*(str: string; pattern: Regex; start = 0, endpos = int.high): RegexMatch =
  var mat = RegexMatch(str: str)
  for m in regex.findAll(str.substr(start, endpos), pattern):
    mat.matchImpl = m
    yield mat

proc find*(str: string; pattern: Regex; start = 0; endpos = int.high): Option[RegexMatch] =
  var mat = default(RegexMatch)
  let r = regex.find(str.substr(start, endpos), pattern, mat.matchImpl)

  # remove following code after regex.find get `start`/`last` parameter
  for v in mat.matchImpl.captures.mitems:
    v.a += start
    v.b += start
  mat.matchImpl.boundaries.a += start
  mat.matchImpl.boundaries.b += start

  if r:
    mat.str = str
    some(mat)
  else:
    none(RegexMatch)

proc findAll*(str: string; pattern: Regex; start = 0; endpos = int.high): seq[string] =
  result = @[]
  for match in str.findIter(pattern, start, endpos):
    result.add(match.match)

proc contains*(str: string; pattern: Regex; start = 0; endpos = int.high): bool =
  isSome(str.find(pattern, start, endpos))

proc split*(str: string; pattern: Regex; maxSplit = -1; start = 0): seq[string] =
  result = splitIncl(str.substr(start), pattern, maxSplit)
  # needs https://github.com/nitely/nim-regex/pull/161
  #result = splitIncl(str, pattern, maxSplit, start)

proc replace*(str: string; pattern: Regex;
              subproc: proc (match: RegexMatch): string): string =
  proc by(m: RegexMatch2, s: string): string =
    let mat = RegexMatch(str: s, matchImpl: m)
    result = subproc(mat)

  result = regex.replace(str, pattern, by)

proc replace*(str: string; pattern: Regex;
              subproc: proc (match: string): string): string =
  proc by(m: RegexMatch2; s: string): string =
    result = subproc(s)

  result = regex.replace(str, pattern, by)

proc replace*(str: string; pattern: Regex; sub: string): string =
  result = regex.replace(str, pattern, sub)

func escapeRe*(str: string): string =
  result = regex.escapeRe(str)
