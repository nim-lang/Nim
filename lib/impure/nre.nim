#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(js):
  {.error: "This library needs to be compiled with a c-like backend, and depends on PCRE2; See jsre for JS backend.".}

## .. warning:: NRE is deprecated.
##   Use [Regex](https://github.com/nitely/nim-regex) or
##   `NRE2 <nre2.html>`_ that wraps Regex so that you can easily replace NRE.
##   This compatibility module uses PCRE2.
##
## What is NRE?
## ============
##
## A regular expression library for Nim using PCRE2 to do the hard work.
##
## For documentation on how to write patterns, there exists `the official PCRE2
## pattern documentation
## <https://www.pcre.org/current/doc/html/pcre2pattern.html>`_. You can also
## search the internet for a wide variety of third-party documentation and
## tools.
##
## .. warning:: If you love `sequtils.toSeq` we have bad news for you. This
##   library doesn't work with it due to documented compiler limitations. As
##   a workaround, use this:
runnableExamples:
  # either `import std/nre except toSeq` or fully qualify `sequtils.toSeq`:
  import std/sequtils
  iterator iota(n: int): int =
    for i in 0..<n: yield i
  assert sequtils.toSeq(iota(3)) == @[0, 1, 2]
## .. note:: There are also alternative nimble packages such as [tinyre](https://github.com/khchen/tinyre)
##   and [regex](https://github.com/nitely/nim-regex).
## Licencing
## ---------
##
## PCRE2 is distributed under a BSD-style licence.
##
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

import std/pcre2 as pcre
import nre/private/util
import std/tables
from std/strutils import `%`
import std/options
from std/unicode import runeLenAt

when defined(nimPreviewSlimSystem):
  import std/assertions

export options

type
  RegexDesc* = object
    pattern*: string
    pcreObj: ptr pcre.Pcre  ## not nil

    captureNameToId: Table[string, int]

  Regex* = ref RegexDesc
    ## Represents the pattern that things are matched against, constructed with
    ## `re(string)`. Examples: `re"foo"`, `re(r"(*ANYCRLF)(?x)foo #
    ## comment")`
    ##
    ## `pattern: string`
    ## :   the string that was used to create the pattern. For details on how
    ##     to write a pattern, please see `the official PCRE2 pattern
    ##     documentation.
    ##     <https://www.pcre.org/current/doc/html/pcre2pattern.html>`_
    ##
    ## `captureCount: int`
    ## :   the number of captures that the pattern has.
    ##
    ## `captureNameId: Table[string, int]`
    ## :   a table from the capture names to their numeric id.
    ##
    ##
    ## Options
    ## .......
    ##
    ## The following options may appear anywhere in the pattern, and they affect
    ## the rest of it.
    ##
    ## -  `(?i)` - case insensitive
    ## -  `(?m)` - multi-line: `^` and `$` match the beginning and end of
    ##    lines, not of the subject string
    ## -  `(?s)` - `.` also matches newline (*dotall*)
    ## -  `(?U)` - expressions are not greedy by default. `?` can be added
    ##    to a qualifier to make it greedy
    ## -  `(?x)` - whitespace and comments (`#`) are ignored (*extended*)
    ## -  `(?X)` - character escapes without special meaning (`\w` vs.
    ##    `\a`) are errors (*extra*)
    ##
    ## One or a combination of these options may appear only at the beginning
    ## of the pattern:
    ##
    ## -  `(*UTF8)` - treat both the pattern and subject as UTF-8
    ## -  `(*UCP)` - Unicode character properties; `\w` matches `я`
    ## -  `(*U)` - a combination of the two options above
    ## -  `(*FIRSTLINE*)` - fails if there is not a match on the first line
    ## -  `(*NO_AUTO_CAPTURE)` - turn off auto-capture for groups;
    ##    `(?<name>...)` can be used to capture
    ## -  `(*CR)` - newlines are separated by `\r`
    ## -  `(*LF)` - newlines are separated by `\n` (UNIX default)
    ## -  `(*CRLF)` - newlines are separated by `\r\n` (Windows default)
    ## -  `(*ANYCRLF)` - newlines are separated by any of the above
    ## -  `(*ANY)` - newlines are separated by any of the above and Unicode
    ##    newlines:
    ##
    ##     single characters VT (vertical tab, U+000B), FF (form feed, U+000C),
    ##     NEL (next line, U+0085), LS (line separator, U+2028), and PS
    ##     (paragraph separator, U+2029). For the 8-bit library, the last two
    ##     are recognized only in UTF-8 mode.
    ##     -- man pcre2pattern
    ##
    ## -  `(*JAVASCRIPT_COMPAT)` - JavaScript compatibility
    ## -  `(*NO_STUDY)` - turn off studying; study is enabled by default
    ##
    ## For more details on the leading option groups, see the `Option
    ## Setting <https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC16>`_
    ## and the `Newline
    ## Convention <https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC17>`_
    ## sections of the `PCRE2 syntax
    ## manual <https://www.pcre.org/current/doc/html/pcre2syntax.html>`_.
    ##
    ## Some of these options are not part of a pattern and are converted by nre
    ## into PCRE2 flags. These include `NEVER_UTF`, `ANCHORED`,
    ## `DOLLAR_ENDONLY`, `FIRSTLINE`, `NO_AUTO_CAPTURE`,
    ## `JAVASCRIPT_COMPAT`, `U`, `NO_STUDY`. In other PCRE2 wrappers, you
    ## will need to pass these as separate flags to PCRE2.

  RegexMatch* = object
    ## Usually seen as `Option[RegexMatch]`, it represents the result of an
    ## execution. On failure, it is none, on success, it is some.
    ##
    ## `pattern: Regex`
    ## :   the pattern that is being matched
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
    pattern*: Regex  ## The regex doing the matching.
                     ## Not nil.
    str*: string  ## The string that was matched against.
    pcreMatchBounds: seq[HSlice[csize_t, csize_t]] ## First item is the bounds of the match
                                            ## Other items are the captures
                                            ## `a` is inclusive start, `b` is exclusive end

  Captures* = distinct RegexMatch
  CaptureBounds* = distinct RegexMatch

  RegexError* = ref object of CatchableError

  RegexInternalError* = ref object of RegexError
    ## Internal error in the module, this probably means that there is a bug

  InvalidUnicodeError* = ref object of RegexError
    ## Thrown when matching fails due to invalid unicode in strings
    pos*: int  ## the location of the invalid unicode in bytes

  SyntaxError* = ref object of RegexError
    ## Thrown when there is a syntax error in the
    ## regular expression string passed in
    pos*: int  ## the location of the syntax error in bytes
    pattern*: string  ## the pattern that caused the problem

  StudyError* = ref object of RegexError
    ## Thrown when studying the regular expression fails
    ## for whatever reason. The message contains the error
    ## code.

when defined(gcDestructors):
  when defined(nimAllowNonVarDestructor) and defined(nimPreviewNonVarDestructor):
    proc `=destroy`(pattern: RegexDesc) =
      `=destroy`(pattern.pattern)
      pcre.code_free(pattern.pcreObj)
      `=destroy`(pattern.captureNameToId)
  else:
    proc `=destroy`(pattern: var RegexDesc) =
      `=destroy`(pattern.pattern)
      pcre.code_free(pattern.pcreObj)
      `=destroy`(pattern.captureNameToId)
else:
  proc destroyRegex(pattern: Regex) =
    `=destroy`(pattern.pattern)
    pcre.code_free(pattern.pcreObj)
    `=destroy`(pattern.captureNameToId)

proc getinfo[T](pattern: Regex, opt: uint32): T =
  result = default(T)
  let retcode = pcre.pattern_info(pattern.pcreObj, opt, addr result)

  if retcode < 0:
    # XXX Error message that doesn't expose implementation details
    raise newException(FieldDefect, "Invalid getinfo for $1, errno $2" % [$opt, $retcode])

proc getNameToNumberTable(pattern: Regex): Table[string, int] =
  let entryCount = getinfo[uint32](pattern, pcre.INFO_NAMECOUNT).int
  let entrySize = getinfo[uint32](pattern, pcre.INFO_NAMEENTRYSIZE).int
  let table = cast[ptr UncheckedArray[uint8]](
                getinfo[pointer](pattern, pcre.INFO_NAMETABLE))

  result = initTable[string, int]()

  for i in 0 ..< entryCount:
    let pos = i * entrySize
    let num = (int(table[pos]) shl 8) or int(table[pos + 1]) - 1
    var name = ""

    var idx = 2
    while table[pos + idx] != 0:
      name.add(char(table[pos + idx]))
      idx += 1

    result[name] = num

proc pcreErrorMessage(errorCode: cint): string =
  var buffer: array[256, uint8]
  let length = pcre.get_error_message(errorCode, addr buffer[0], buffer.len.csize_t)
  if length >= 0:
    result = newString(length)
    if length > 0:
      copyMem(addr result[0], addr buffer[0], length)
  else:
    result = $errorCode

proc jitCompile(pattern: ptr pcre.Pcre) =
  var hasJit: cint = 0
  if pcre.config(pcre.CONFIG_JIT, addr hasJit) == 0 and hasJit == 1:
    discard pcre.jit_compile(pattern, pcre.JIT_COMPLETE.uint32)

proc initRegex(pattern: string, flags: uint32, study = true): Regex =
  when defined(gcDestructors):
    result = Regex()
  else:
    new(result, destroyRegex)
  result.pattern = pattern

  var
    errorCode: cint = 0
    errOffset: csize_t = 0

  result.pcreObj = pcre.compile(cast[ptr uint8](cstring(pattern)),
                                pattern.len.csize_t, flags, addr errorCode,
                                addr errOffset, nil)
  if result.pcreObj == nil:
    # failed to compile
    raise SyntaxError(msg: pcreErrorMessage(errorCode), pos: errOffset.int,
                      pattern: pattern)

  if study:
    jitCompile(result.pcreObj)

  result.captureNameToId = result.getNameToNumberTable()

proc captureCount*(pattern: Regex): int =
  return getinfo[uint32](pattern, pcre.INFO_CAPTURECOUNT).int

proc captureNameId*(pattern: Regex): Table[string, int] =
  return pattern.captureNameToId

proc matchesCrLf(pattern: Regex): bool =
  let newline = getinfo[uint32](pattern, pcre.INFO_NEWLINE)
  case newline
  of pcre.NEWLINE_CRLF, pcre.NEWLINE_ANY, pcre.NEWLINE_ANYCRLF:
    return true
  of pcre.NEWLINE_CR, pcre.NEWLINE_LF, pcre.NEWLINE_NUL:
    return false
  else:
    discard

  # get flags from build config
  var confFlags: uint32 = 0
  if pcre.config(pcre.CONFIG_NEWLINE, addr confFlags) != 0:
    assert(false, "CONFIG_NEWLINE apparently got screwed up")

  case confFlags
  of pcre.NEWLINE_CR, pcre.NEWLINE_LF, pcre.NEWLINE_NUL: return false
  of pcre.NEWLINE_CRLF, pcre.NEWLINE_ANY, pcre.NEWLINE_ANYCRLF: return true
  else: return false


func captureBounds*(pattern: RegexMatch): CaptureBounds = return CaptureBounds(pattern)

func captures*(pattern: RegexMatch): Captures = return Captures(pattern)

func contains*(pattern: CaptureBounds, i: int): bool =
  let pattern = RegexMatch(pattern)
  let index = i + 1
  index >= 0 and index < pattern.pcreMatchBounds.len and
    pattern.pcreMatchBounds[index].a != pcre.UNSET

func contains*(pattern: Captures, i: int): bool =
  i in CaptureBounds(pattern)

func `[]`*(pattern: CaptureBounds, i: int): HSlice[int, int] =
  let pattern = RegexMatch(pattern)
  if not (i in pattern.captureBounds):
    raise newException(IndexDefect, "Group '" & $i & "' was not captured")

  let bounds = pattern.pcreMatchBounds[i + 1]
  int(bounds.a) .. (int(bounds.b) - 1)

func `[]`*(pattern: Captures, i: int): string =
  let pattern = RegexMatch(pattern)
  let bounds = pattern.captureBounds[i]

  pattern.str.substr(bounds.a, bounds.b)

func match*(pattern: RegexMatch): string =
  return pattern.captures[-1]

func matchBounds*(pattern: RegexMatch): HSlice[int, int] =
  return pattern.captureBounds[-1]

func contains*(pattern: CaptureBounds, name: string): bool =
  let pattern = RegexMatch(pattern)
  let nameToId = pattern.pattern.captureNameToId
  if not (name in nameToId):
      return false
  nameToId[name] in pattern.captureBounds

func contains*(pattern: Captures, name: string): bool =
  name in CaptureBounds(pattern)

func checkNamedCaptured(pattern: RegexMatch, name: string) =
  if not (name in pattern.captureBounds):
    raise newException(KeyError, "Group '" & name & "' was not captured")

func `[]`*(pattern: CaptureBounds, name: string): HSlice[int, int] =
  let pattern = RegexMatch(pattern)
  checkNamedCaptured(pattern, name)
  {.noSideEffect.}:
    result = pattern.captureBounds[pattern.pattern.captureNameToId[name]]

func `[]`*(pattern: Captures, name: string): string =
  let pattern = RegexMatch(pattern)
  checkNamedCaptured(pattern, name)
  {.noSideEffect.}:
    result = pattern.captures[pattern.pattern.captureNameToId[name]]

template toTableImpl() {.dirty.} =
  for key in RegexMatch(pattern).pattern.captureNameId.keys:
    if key in pattern:
      result[key] = pattern[key]

func toTable*(pattern: Captures): Table[string, string] =
  result = initTable[string, string]()
  toTableImpl()

func toTable*(pattern: CaptureBounds): Table[string, HSlice[int, int]] =
  result = initTable[string, HSlice[int, int]]()
  toTableImpl()

template itemsImpl() {.dirty.} =
  for i in 0 ..< RegexMatch(pattern).pattern.captureCount:
    # done in this roundabout way to avoid multiple yields (potential code
    # bloat)
    let nextYieldVal = if i in pattern:
      some(pattern[i])
    else:
      default

    yield nextYieldVal

iterator items*(pattern: CaptureBounds,
                default = none(HSlice[int, int])): Option[HSlice[int, int]] =
  itemsImpl()

iterator items*(pattern: Captures,
                default: Option[string] = none(string)): Option[string] =
  itemsImpl()

proc toSeq*(pattern: CaptureBounds,
            default = none(HSlice[int, int])): seq[Option[HSlice[int, int]]] =
  result = @[]
  for it in pattern.items(default): result.add it

proc toSeq*(pattern: Captures,
            default: Option[string] = none(string)): seq[Option[string]] =
  result = @[]
  for it in pattern.items(default): result.add it

proc `$`*(pattern: RegexMatch): string =
  return pattern.captures[-1]

proc `==`*(a, b: Regex): bool =
  if not a.isNil and not b.isNil:
    return a.pattern == b.pattern and
           a.pcreObj == b.pcreObj
  else:
    return system.`==`(a, b)

proc `==`*(a, b: RegexMatch): bool =
  return a.pattern == b.pattern and
         a.str == b.str

const PcreOptions = {
  "NEVER_UTF": pcre.NEVER_UTF,
  "ANCHORED": pcre.ANCHORED,
  "DOLLAR_ENDONLY": pcre.DOLLAR_ENDONLY,
  "FIRSTLINE": pcre.FIRSTLINE,
  "NO_AUTO_CAPTURE": pcre.NO_AUTO_CAPTURE,
  "JAVASCRIPT_COMPAT": pcre.JAVASCRIPT_COMPAT,
  "U": pcre.UTF or pcre.UCP
}.toTable

# Options that are supported inside regular expressions themselves
const SkipOptions = [
  "LIMIT_MATCH=", "LIMIT_RECURSION=", "NO_AUTO_POSSESS", "NO_START_OPT",
  "UTF8", "UTF16", "UTF32", "UTF", "UCP",
  "CR", "LF", "CRLF", "ANYCRLF", "ANY", "BSR_ANYCRLF", "BSR_UNICODE"
]

proc extractOptions(pattern: string): tuple[pattern: string, flags: int, study: bool] =
  result = ("", 0, true)

  var optionStart = 0
  var equals = false
  for i, c in pattern:
    if optionStart == i:
      if c != '(':
        break
      optionStart = i

    elif optionStart == i-1:
      if c != '*':
        break

    elif c == ')':
      let name = pattern[optionStart+2 .. i-1]
      if equals or name in SkipOptions:
        result.pattern.add pattern[optionStart .. i]
      elif PcreOptions.hasKey name:
        result.flags = result.flags or PcreOptions[name]
      elif name == "NO_STUDY":
        result.study = false
      else:
        break
      optionStart = i+1
      equals = false

    elif not equals:
      if c == '=':
        equals = true
        if pattern[optionStart+2 .. i] notin SkipOptions:
          break
      elif c notin {'A'..'Z', '0'..'9', '_'}:
        break

  result.pattern.add pattern[optionStart .. pattern.high]

proc re*(pattern: string): Regex =
  let (pattern, flags, study) = extractOptions(pattern)
  initRegex(pattern, cast[uint32](flags), study)

func isInvalidUnicodeError(errorCode: cint): bool =
  (errorCode <= pcre.ERROR_UTF8_ERR1 and errorCode >= pcre.ERROR_UTF8_ERR21) or
    errorCode == pcre.ERROR_BADUTFOFFSET or
    errorCode == pcre.ERROR_DFA_UINVALID_UTF

proc newMatchData(pattern: Regex): ptr pcre.MatchData =
  result = pcre.match_data_create_from_pattern(pattern.pcreObj, nil)
  if result == nil:
    raise RegexInternalError(msg: "could not allocate PCRE2 match data")

proc matchImpl(str: string, pattern: Regex, start, endpos: int, options: uint32): Option[RegexMatch] =
  var myResult = RegexMatch(pattern: pattern, str: str)
  myResult.pcreMatchBounds = newSeq[HSlice[csize_t, csize_t]](pattern.captureCount() + 1)

  let strlen = if endpos == int.high: str.len else: endpos+1
  doAssert(strlen <= str.len)  # don't want buffer overflows
  if start < 0 or start > strlen:
    return none(RegexMatch)

  let matchData = newMatchData(pattern)
  defer: pcre.match_data_free(matchData)
  let execRet = pcre.match(pattern.pcreObj,
                           cast[ptr uint8](cstring(str)),
                           strlen.csize_t,
                           start.csize_t,
                           options,
                           matchData,
                           nil)
  let rawMatches = cast[ptr UncheckedArray[csize_t]](pcre.get_ovector_pointer(matchData))
  let ovectorCount = min(myResult.pcreMatchBounds.len,
                         pcre.get_ovector_count(matchData).int)
  for i in 0 ..< ovectorCount:
    myResult.pcreMatchBounds[i] = rawMatches[i * 2] .. rawMatches[i * 2 + 1]

  if execRet >= 0:
    return some(myResult)

  if isInvalidUnicodeError(execRet):
    let errorPos = if myResult.pcreMatchBounds.len > 0 and
        myResult.pcreMatchBounds[0].a != pcre.UNSET:
      myResult.pcreMatchBounds[0].a.int
    else:
      start
    raise InvalidUnicodeError(msg: "Invalid unicode byte sequence", pos: errorPos)

  case execRet
  of pcre.ERROR_NOMATCH:
    return none(RegexMatch)
  of pcre.ERROR_NULL:
    raise newException(AccessViolationDefect, "Expected non-null parameters")
  of pcre.ERROR_BADOPTION:
    raise RegexInternalError(msg: "Unknown pattern flag. Either a bug or " &
      "outdated PCRE2.")
  else:
    raise RegexInternalError(msg: "Unknown internal error: " & $execRet)

proc match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  ## Like `find(...)<#find,string,Regex,int>`_, but anchored to the start of the
  ## string.
  runnableExamples:
    assert "foo".match(re"f").isSome
    assert "foo".match(re"o").isNone

    assert "abc".match(re"(\w)").get.captures[0] == "a"
    assert "abc".match(re"(?<letter>\w)").get.captures["letter"] == "a"
    assert "abc".match(re"(\w)\w").get.captures[-1] == "ab"

    assert "abc".match(re"(\w)").get.captureBounds[0] == 0 .. 0
    assert 0 in "abc".match(re"(\w)").get.captureBounds
    assert "abc".match(re"").get.captureBounds[-1] == 0 .. -1
    assert "abc".match(re"abc").get.captureBounds[-1] == 0 .. 2
  return str.matchImpl(pattern, start, endpos, cast[uint32](pcre.ANCHORED))

iterator findIter*(str: string, pattern: Regex, start = 0, endpos = int.high): RegexMatch =
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
  # see pcre2demo for explanation => https://www.pcre.org/current/doc/html/pcre2demo.html
  let matchesCrLf = pattern.matchesCrLf()
  let unicode = uint32(getinfo[uint32](pattern, pcre.INFO_ALLOPTIONS) and
    pcre.UTF.uint32) > 0u32
  let strlen = if endpos == int.high: str.len else: endpos+1
  var offset = start
  var match: Option[RegexMatch] = default(Option[RegexMatch])
  var neverMatched = true

  while true:
    var flags = 0'u32
    if match.isSome and
       match.get.matchBounds.a > match.get.matchBounds.b:
      # 0-len match
      flags = pcre.NOTEMPTY_ATSTART.uint32
    match = str.matchImpl(pattern, offset, endpos, flags)

    if match.isNone:
      # either the end of the input or the string
      # cannot be split here - we also need to bail
      # if we've never matched and we've already tried to...
      if flags == 0 or offset >= strlen or neverMatched: # All matches found
        break

      if matchesCrLf and offset < (str.len - 1) and
         str[offset] == '\r' and str[offset + 1] == '\L':
        # if PCRE treats CrLf as newline, skip both at the same time
        offset += 2
      elif unicode:
        # XXX what about invalid unicode?
        offset += str.runeLenAt(offset)
        assert(offset <= strlen)
      else:
        offset += 1
    else:
      neverMatched = false
      offset = match.get.matchBounds.b + 1
      yield match.get

proc find*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
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
  return str.matchImpl(pattern, start, endpos, 0'u32)

proc findAll*(str: string, pattern: Regex, start = 0, endpos = int.high): seq[string] =
  result = @[]
  for match in str.findIter(pattern, start, endpos):
    result.add(match.match)

proc contains*(str: string, pattern: Regex, start = 0, endpos = int.high): bool =
  ## Determine if the string contains the given pattern between the end and
  ## start positions:
  ## This function is equivalent to `isSome(str.find(pattern, start, endpos))`.
  runnableExamples:
    assert "abc".contains(re"bc")
    assert not "abc".contains(re"cd")
    assert not "abc".contains(re"a", start = 1)

  return isSome(str.find(pattern, start, endpos))

proc split*(str: string, pattern: Regex, maxSplit = -1, start = 0): seq[string] =
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

  result = @[]
  var lastIdx = start
  var splits = 0
  var bounds = 0 .. -1
  var never_ran = true

  for match in str.findIter(pattern, start = start):
    never_ran = false

    # bounds are inclusive:
    #
    # 0123456
    #  ^^^
    # (1, 3)
    bounds = match.matchBounds

    # "12".split("") would be @["", "1", "2"], but
    # if we skip an empty first match, it's the correct
    # @["1", "2"]
    if bounds.a <= bounds.b or bounds.a > start:
      result.add(str.substr(lastIdx, bounds.a - 1))
      splits += 1

    lastIdx = bounds.b + 1

    for cap in match.captures:
      # if there are captures, include them in the result
      if cap.isSome:
        result.add(cap.get)

    if splits == maxSplit - 1:
      break

  # "12".split("\b") would be @["1", "2", ""], but
  # if we skip an empty last match, it's the correct
  # @["1", "2"]
  # If matches were never found, then the input string is the result
  if bounds.a <= bounds.b or bounds.b < str.high or never_ran:
    # last match: Each match takes the previous substring,
    # but "1 2".split(/ /) needs to return @["1", "2"].
    # This handles "2"
    result.add(str.substr(bounds.b + 1, str.high))

template replaceImpl(str: string, pattern: Regex,
                     replacement: untyped) {.dirty.} =
  # XXX seems very similar to split, maybe I can reduce code duplication
  # somehow?
  result = ""
  var lastIdx = 0
  for match {.inject.} in str.findIter(pattern):
    let bounds = match.matchBounds
    result.add(str.substr(lastIdx, bounds.a - 1))
    let nextVal = replacement
    result.add(nextVal)

    lastIdx = bounds.b + 1

  result.add(str.substr(lastIdx, str.len - 1))
  return result

proc replace*(str: string, pattern: Regex,
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
  ## -  `$foo` - named capture `foo`
  ## -  `${foo}` - same as above
  ## -  `$1$#` - first and second captures
  ## -  `$#` - first capture
  ## -  `$0` - full match
  ##
  ## If a given capture is missing, `IndexDefect` thrown for un-named captures
  ## and `KeyError` for named captures.
  replaceImpl(str, pattern, subproc(match))

proc replace*(str: string, pattern: Regex,
              subproc: proc (match: string): string): string =
  replaceImpl(str, pattern, subproc(match.match))

proc replace*(str: string, pattern: Regex, sub: string): string =
  # - 1 because the string numbers are 0-indexed
  replaceImpl(str, pattern,
    formatStr(sub, match.captures[name], match.captures[id - 1]))

proc escapeRe*(str: string): string {.gcsafe.} =
  ## Escapes the string so it doesn't match any special characters.
  ## Incompatible with the Extra flag (`X`).
  ##
  ## Escaped char: `\ + * ? [ ^ ] $ ( ) { } = ! < > | : -`
  runnableExamples:
    assert escapeRe("fly+wind") == "fly\\+wind"
    assert escapeRe("!") == "\\!"
    assert escapeRe("nim*") == "nim\\*"

  #([\\+*?[^\]$(){}=!<>|:-])
  const SpecialCharMatcher = {'\\', '+', '*', '?', '[', '^', ']', '$', '(',
                              ')', '{', '}', '=', '!', '<', '>', '|', ':',
                              '-'}
  result = ""
  for c in items(str):
    case c
    of SpecialCharMatcher:
      result.add("\\")
      result.add(c)
    else:
      result.add(c)
