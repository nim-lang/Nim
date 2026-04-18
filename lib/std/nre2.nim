#
#            Nim's Runtime Library
#        (c) Copyright 2026 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## What is NRE2?
## =============
##
## A regular expression library for Nim to replace deprecated NRE.
## It is implemented with `Regex<https://github.com/nitely/nim-regex>`_ ,
## that is pure Nim regex engine and guarantees linear time matching.
## It supports compiling regex and matching at compile-time and
## works with JS backend.
##
## NRE2 is mostly compatible with NRE and the syntax of regular expression is similar to PCRE.
## But it lacks a few features and how to set options in a pattern is different.
##
## The syntax of regular expression is explained in https://nitely.github.io/nim-regex/regex.html
runnableExamples:
  import std/sugar
  let vowels = re"[aeoui]"
  let bounds = collect:
    for match in "moiga".findIter(vowels): match.matchBounds
  assert bounds == @[1 .. 1, 2 .. 2, 4 .. 4]
  from std/sequtils import toSeq
  let s = sequtils.toSeq("moiga".findIter(vowels))
    # fully qualified to avoid confusion with nre.toSeq
  assert s.len == 3

  let firstVowel = "foo".find(vowels)
  let hasVowel = firstVowel.isSome()
  assert hasVowel
  let matchBounds = firstVowel.get().captureBounds[-1]
  assert matchBounds.a == 1

  # as with module `re`, unless specified otherwise, `start` parameter in each
  # proc indicates where the scan starts, but outputs are relative to the start
  # of the input string, not to `start`:
  assert find("uxabc", re"(?<=x|y)ab", start = 1).get.captures[-1] == "ab"
  assert find("uxabc", re"ab", start = 3).isNone

import std/[options, tables]
import regex, regex/nfatype

export options
export regex.RegexFlags, regex.RegexError

type
  Regex* = regex.Regex2
    ## Represents the pattern that things are matched against, constructed with
    ## `re(string)`. Examples: `re"foo"`, `re(r"(?x)foo #comment")`
    ##
    ## `captureCount: int`
    ## :   the number of captures that the pattern has.
    ##
    ## `captureNameId: Table[string, int]`
    ## :   a table from the capture names to their numeric id.
    ##
    ## The syntax of regular expression of Regex is explained in https://nitely.github.io/nim-regex/regex.html

  RegexMatch* = object
    ## Usually seen as `Option[RegexMatch]`, it represents the result of an
    ## execution. On failure, it is none, on success, it is some.
    ##
    ## `str: string`
    ## :   the string that was matched against
    ##
    ## `captures[]: string`
    ## :   the string value of whatever was captured at that id. If the value
    ##     is invalid, then behavior is undefined. If the id is `-1`, then
    ##     the whole match is returned. If the given capture was not matched,
    ##     `nil` is returned. See examples for `match`.
    ##
    ## `captureBounds[]: HSlice[int, int]`
    ## :   gets the bounds of the given capture according to the same rules as
    ##     the above. If the capture is not filled, then `None` is returned.
    ##     The bounds are both inclusive.  See examples for `match`.
    ##
    ## `match: string`
    ## :   the full text of the match.
    ##
    ## `matchBounds: HSlice[int, int]`
    ## :   the bounds of the match, as in `captureBounds[]`
    ##
    ## `(captureBounds|captures).toTable`
    ## :   returns a table with each named capture as a key.
    ##
    ## `(captureBounds|captures).toSeq`
    ## :   returns all the captures by their number.
    ##
    ## `$: string`
    ## :   same as `match`
    str*: string  ## The string that was matched against.
    matchImpl: regex.RegexMatch2

  Captures* {.borrow: `.`.} = distinct RegexMatch
  CaptureBounds* {.borrow: `.`.} = distinct RegexMatch

func captureCount*(pattern: Regex): int {.inline.} =
  pattern.toRegex().groupsCount

func captureNameId*(pattern: Regex): Table[string, int] =
  result = initTable[string, int](pattern.toRegex().namedGroups.len)
  for k, v in pattern.toRegex().namedGroups:
    result[k] = v

func captureBounds*(match: RegexMatch): CaptureBounds {.inline.} =
  CaptureBounds(match)

func captures*(match: RegexMatch): Captures {.inline.} =
  Captures(match)

func contains*(match: Captures or CaptureBounds, i: int): bool {.inline.} =
  i >= -1 and i < match.matchImpl.groupsCount and match.matchImpl.group(i) != reNonCapture

func len*(match: Captures or CaptureBounds): int {.inline.} =
  ## Return the number of capturing groups
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
  ## Parse and compile a regular expression at compile-time
  result = regex.re2(pattern, flags)

func re*(pattern: string; flags: RegexFlags = {}): Regex =
  ## Parse and compile a regular expression at run-time
  result = regex.re2(pattern, flags)

func match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  ## Like `find(...)<#find,string,Regex,int>`_, but anchored to the start of the
  ## string.
  runnableExamples:
    assert "foo".match(re"f").isSome
    assert "foo".match(re"o").isNone

    assert "abc".match(re"(\w)").get.captures[0] == "a"
    assert "abc".match(re"(?P<letter>\w)").get.captures["letter"] == "a"
    assert "abc".match(re"(\w)\w").get.captures[-1] == "ab"

    assert "abc".match(re"(\w)").get.captureBounds[0] == 0 .. 0
    assert 0 in "abc".match(re"(\w)").get.captureBounds
    assert "abc".match(re"").get.captureBounds[-1] == 0 .. -1
    assert "abc".match(re"abc").get.captureBounds[-1] == 0 .. 2
  var mat = default(RegexMatch)
  let r = regex.startsWith(str.toOpenArray(0, min(str.high, endpos)), pattern, mat.matchImpl, start)
  if r:
    mat.str = str
    some(mat)
  else:
    none(RegexMatch)

iterator findIter*(str: string; pattern: Regex; start = 0, endpos = int.high): RegexMatch =
  ## Works the same as `find(...)<#find,string,Regex,int>`_, but finds every
  ## non-overlapping match:
  runnableExamples:
    import std/sugar
    assert collect(for a in "2222".findIter(re"22"): a.match) == @["22", "22"]
     # not @["22", "22", "22"]
  ## Arguments are the same as `find(...)<#find,string,Regex,int>`_
  ##
  ## Variants:
  ##
  ## -  `proc findAll(...)` returns a `seq[string]`
  var mat = RegexMatch(str: str)
  # TODO:
  # needs following PR to remove `substr` call.
  # https://github.com/nitely/nim-regex/pull/162
  for m in regex.findAll(str.substr(start, endpos), pattern):
    mat.matchImpl = m
    yield mat

proc find*(str: string; pattern: Regex; start = 0; endpos = int.high): Option[RegexMatch] =
  ## Finds the given pattern in the string between the end and start
  ## positions.
  ##
  ## `start`
  ## :   The start point at which to start matching. `|abc` is `0`;
  ##     `a|bc` is `1`
  ##
  ## `endpos`
  ## :   The maximum index for a match; `int.high` means the end of the
  ##     string, otherwise it’s an inclusive upper bound.
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
  ## Determine if the string contains the given pattern between the end and
  ## start positions:
  ## This function is equivalent to `isSome(str.find(pattern, start, endpos))`.
  runnableExamples:
    assert "abc".contains(re"bc")
    assert not "abc".contains(re"cd")
    assert not "abc".contains(re"a", start = 1)

  isSome(str.find(pattern, start, endpos))

proc split*(str: string; pattern: Regex; maxSplit = -1; start = 0): seq[string] =
  ## Splits the string with the given regex. This works according to the
  ## rules that Perl and Javascript use.
  ##
  ## `start` behaves the same as in `find(...)<#find,string,Regex,int>`_.
  ##
  runnableExamples:
    # -  If the match is zero-width, then the string is still split:
    assert "123".split(re"") == @["1", "2", "3"]

    # -  If the pattern has a capture in it, it is added after the string
    #    split:
    assert "12".split(re"(\d)") == @["", "1", "", "2", ""]

    # -  If `maxsplit != -1`, then the string will only be split
    #    `maxsplit - 1` times. This means that there will be `maxsplit`
    #    strings in the output seq.
    assert "1.2.3".split(re"\.", maxsplit = 2) == @["1", "2.3"]

  result = splitIncl(str, pattern, maxSplit, start)

proc replace*(str: string; pattern: Regex;
              subproc: proc (match: RegexMatch): string): string =
  ## Replaces each match of Regex in the string with `subproc`, which should
  ## never be or return `nil`.
  ##
  ## If `subproc` is a `proc (RegexMatch): string`, then it is executed with
  ## each match and the return value is the replacement value.
  ##
  ## If `subproc` is a `proc (string): string`, then it is executed with the
  ## full text of the match and the return value is the replacement value.
  ##
  ## If `subproc` is a string, the syntax is as follows:
  ##
  ## -  `$$` - literal `$`
  ## -  `$123` - capture number `123`
  ## -  `$1$#` - first and second captures
  ## -  `$#` - first capture
  ##
  ## Following syntax is not supported in NRE2
  ##
  ## -  `$foo` - named capture `foo`
  ## -  `${foo}` - same as above
  ## -  `$0` - full match
  ##
  ## If a given capture is missing, `ValueError` is thrown.
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
  ## Escapes the string so it doesn't match any special characters.
  runnableExamples:
    assert escapeRe("fly+wind") == "fly\\+wind"
    assert escapeRe("nim*") == "nim\\*"

  result = regex.escapeRe(str)
