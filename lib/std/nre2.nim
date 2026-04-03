#
#            Nim's Runtime Library
#        (c) Copyright 2026 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std/[options, tables]
import regex

type
  Regex* = regex.Regex2
  RegexMatch* = object
    str*: string
    matchImpl: regex.RegexMatch2

  Captures* {.borrow: `.`.} = distinct RegexMatch
  CaptureBounds* {.borrow: `.`.} = distinct RegexMatch

export regex.RegexFlags, regex.RegexError

func captureBounds*(match: RegexMatch): CaptureBounds {.inline.} = CaptureBounds(match)

func captures*(match: RegexMatch): Captures {.inline.} = Captures(match)

func contains*(match: Captures or CaptureBounds, i: int): bool {.inline.} =
  i >= -1 and i < match.matchImpl.groupsCount and match.matchImpl.group(i) != reNonCapture

func len*(match: Captures or CaptureBounds): int =
  match.matchImpl.groupsCount

func `[]`*(match: CaptureBounds; i: int): HSlice[int, int] =
  if i == -1: match.matchImpl.boundaries else: match.matchImpl.group(i)

func `[]`*(match: CaptureBounds; name: string): HSlice[int, int] =
  match.matchImpl.group(name)

func `[]`*(match: Captures; i: int): string =
  match.str[CaptureBounds(match)[i]]

func `[]`*(match: Captures, name: string): string =
  match.str[match.matchImpl.group(name)]

func match*(match: RegexMatch): string =
  match.str[match.matchImpl.boundaries]

func matchBounds*(match: RegexMatch): Slice[int] =
  match.matchImpl.boundaries

func toTable*(match: Captures): Table[string, string] =
  result = initTable[string, string]()
  for k, i in match.matchImpl.namedGroups:
    result[k] = match.str[match.matchImpl.group(i)]

func toTable*(match: CaptureBounds): Table[string, HSlice[int, int]] =
  result = initTable[string, HSlice[int, int]]()
  for k, i in match.matchImpl.namedGroups:
    result[k] = match.matchImpl.group(i)

func re*(pattern: static string; flags: static RegexFlags = {}): static[Regex2] =
  result = regex.re2(pattern, flags)

func re*(pattern: string; flags: RegexFlags = {}): Regex =
  result = regex.re2(pattern, flags)

func match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  var mat = default(RegexMatch)
  # TODO
  # remove `substr` when nim-regex procs support start/end parameters
  let r = regex.match(str.substr(start, endpos), pattern, mat.matchImpl)
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
  if r:
    mat.str = str
    some(mat)
  else:
    none(RegexMatch)

proc contains*(str: string; pattern: Regex; start = 0; endpos = int.high): bool =
  isSome(str.find(pattern, start, endpos))

proc split*(str: string, pattern: Regex, maxSplit = -1, start = 0): seq[string] =
  result = splitIncl(str.substr(start), pattern)

proc findAll*(str: string; pattern: Regex; start = 0; endpos = int.high): seq[string] =
  result = @[]
  for match in str.findIter(pattern, start, endpos):
    result.add(match.match)

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
