import private.pcre as pcre
import private.util
import tables
import unsigned
from future import lc, `[]`
from strutils import toLower, `%`
from math import ceil
import optional_t
from unicode import runeLenAt

# Type definitions {{{
type
  Regex* = ref object
    ## Represents a compiled pattern
    pattern*: string  ## not nil
    pcreObj: ptr pcre.Pcre  ## not nil
    pcreExtra: ptr pcre.ExtraData  ## nil

    captureNameToId: Table[string, int]

  RegexMatch* = ref object
    ## Is returned upon a match.
    pattern*: Regex  ## The regex doing the matching.
                     ## Not nil.
    str*: string  ## The string that was matched against.
                  ## Not nil.
    pcreMatchBounds: seq[Slice[cint]] ## First item is the bounds of the match
                                      ## Other items are the captures
                                      ## `a` is inclusive start, `b` is exclusive end
    matchCache: seq[string]

  Captures* = distinct RegexMatch
  CaptureBounds* = distinct RegexMatch

  SyntaxError* = ref object of Exception
    ## Thrown when there is a syntax error in the
    ## regular expression string passed in
    pos*: int  ## the location of the syntax error in bytes
    pattern*: string  ## the pattern that caused the problem

  StudyError* = ref object of Exception
    ## Thrown when studying the regular expression failes
    ## for whatever reason. The message contains the error
    ## code.
# }}}

proc getinfo[T](pattern: Regex, opt: cint): T =
  let retcode = pcre.fullinfo(pattern.pcreObj, pattern.pcreExtra, opt, addr result)

  if retcode < 0:
    # XXX Error message that doesn't expose implementation details
    raise newException(FieldError, "Invalid getinfo for $1, errno $2" % [$opt, $retcode])

# Regex accessors {{{
proc captureCount*(pattern: Regex): int =
  ## Get the maximum number of captures
  ##
  ## Does not return the number of captured captures
  return getinfo[int](pattern, pcre.INFO_CAPTURECOUNT)

proc captureNameId*(pattern: Regex): Table[string, int] =
  ## Returns a map from named capture groups to their numerical
  ## identifier
  return pattern.captureNameToId

proc matchesCrLf(pattern: Regex): bool =
  let flags = getinfo[cint](pattern, pcre.INFO_OPTIONS)
  let newlineFlags = flags and (pcre.NEWLINE_CRLF or
                                pcre.NEWLINE_ANY or
                                pcre.NEWLINE_ANYCRLF)
  if newLineFlags > 0:
    return true

  # get flags from build config
  var confFlags: cint
  if pcre.config(pcre.CONFIG_NEWLINE, addr confFlags) != 0:
    assert(false, "CONFIG_NEWLINE apparently got screwed up")

  case confFlags
  of 13: return false
  of 10: return false
  of (13 shl 8) or 10: return true
  of -2: return true
  of -1: return true
  else: return false
# }}}

# Capture accessors {{{
proc captureBounds*(pattern: RegexMatch): CaptureBounds = return CaptureBounds(pattern)

proc captures*(pattern: RegexMatch): Captures = return Captures(pattern)

proc `[]`*(pattern: CaptureBounds, i: int): Option[Slice[int]] =
  ## Gets the bounds of the `i`th capture.
  ## Undefined behavior if `i` is out of bounds
  ## If `i` is a failed optional capture, returns None
  ## If `i == -1`, returns the whole match
  let pattern = RegexMatch(pattern)
  if pattern.pcreMatchBounds[i + 1].a != -1:
    let bounds = pattern.pcreMatchBounds[i + 1]
    return Some(int(bounds.a) .. int(bounds.b))
  else:
    return None[Slice[int]]()

proc `[]`*(pattern: Captures, i: int): string =
  ## gets the `i`th capture
  ## Undefined behavior if `i` is out of bounds
  ## If `i` is a failed optional capture, returns nil
  ## If `i == -1`, returns the whole match
  let pattern = RegexMatch(pattern)
  let bounds = pattern.captureBounds[i]

  if bounds:
    let bounds = bounds.get
    if pattern.matchCache == nil:
      # capture count, plus the entire string
      pattern.matchCache = newSeq[string](pattern.pattern.captureCount + 1)
    if pattern.matchCache[i + 1] == nil:
      pattern.matchCache[i + 1] = pattern.str[bounds.a .. bounds.b-1]
    return pattern.matchCache[i + 1]
  else:
    return nil

proc match*(pattern: RegexMatch): string =
  return pattern.captures[-1]

proc matchBounds*(pattern: RegexMatch): Slice[int] =
  return pattern.captureBounds[-1].get

proc `[]`*(pattern: CaptureBounds, name: string): Option[Slice[int]] =
  ## Will fail with KeyError if `name` is not a real named capture
  let pattern = RegexMatch(pattern)
  return pattern.captureBounds[pattern.pattern.captureNameToId.fget(name)]

proc `[]`*(pattern: Captures, name: string): string =
  ## Will fail with KeyError if `name` is not a real named capture
  let pattern = RegexMatch(pattern)
  return pattern.captures[pattern.pattern.captureNameToId.fget(name)]

template toTableImpl(cond: bool): stmt {.immediate, dirty.} =
  for key in RegexMatch(pattern).pattern.captureNameId.keys:
    let nextVal = pattern[key]
    if cond:
      result[key] = default
    else:
      result[key] = nextVal

proc toTable*(pattern: Captures, default: string = nil): Table[string, string] =
  ## Gets all the named captures and returns them
  result = initTable[string, string]()
  toTableImpl(nextVal == nil)

proc toTable*(pattern: CaptureBounds, default = None[Slice[int]]()):
    Table[string, Option[Slice[int]]] =
  ## Gets all the named captures and returns them
  result = initTable[string, Option[Slice[int]]]()
  toTableImpl(nextVal.isNone)

template itemsImpl(cond: bool): stmt {.immediate, dirty.} =
  for i in 0 .. <RegexMatch(pattern).pattern.captureCount:
    let nextVal = pattern[i]
    if cond:
      yield default
    else:
      yield nextVal

iterator items*(pattern: CaptureBounds, default = None[Slice[int]]()): Option[Slice[int]] =
  itemsImpl(nextVal.isNone)

iterator items*(pattern: Captures, default: string = nil): string =
  itemsImpl(nextVal == nil)

proc toSeq*(pattern: CaptureBounds, default = None[Slice[int]]()): seq[Option[Slice[int]]] =
  accumulateResult(pattern.items(default))

proc toSeq*(pattern: Captures, default: string = nil): seq[string] =
  accumulateResult(pattern.items(default))

proc `$`*(pattern: RegexMatch): string =
  return pattern.captures[-1]
# }}}

# Creation & Destruction {{{
# PCRE Options {{{
let Options: Table[string, int] = {
  "8" : pcre.UTF8,
  "9" : pcre.NEVER_UTF,
  "A" : pcre.ANCHORED,
  # "C" : pcre.AUTO_CALLOUT, unsuported XXX
  "E" : pcre.DOLLAR_ENDONLY,
  "f" : pcre.FIRSTLINE,
  "i" : pcre.CASELESS,
  "m" : pcre.MULTILINE,
  "N" : pcre.NO_AUTO_CAPTURE,
  "s" : pcre.DOTALL,
  "U" : pcre.UNGREEDY,
  "u" : pcre.UTF8,
  "W" : pcre.UCP,
  "X" : pcre.EXTRA,
  "x" : pcre.EXTENDED,
  "Y" : pcre.NO_START_OPTIMIZE,

  "any"         : pcre.NEWLINE_ANY,
  "anycrlf"     : pcre.NEWLINE_ANYCRLF,
  "cr"          : pcre.NEWLINE_CR,
  "crlf"        : pcre.NEWLINE_CRLF,
  "lf"          : pcre.NEWLINE_LF,
  "bsr_anycrlf" : pcre.BSR_ANYCRLF,
  "bsr_unicode" : pcre.BSR_UNICODE,
  "js"          : pcre.JAVASCRIPT_COMPAT,
}.toTable

proc tokenizeOptions(opts: string): tuple[flags: int, study: bool] =
  result = (0, true)

  var longOpt: string = nil
  for i, c in opts:
    # Handle long options {{{
    if c == '<':
      longOpt = ""
      continue

    if longOpt != nil:
      if c == '>':
        if longOpt == "no_study":
          result.study = false
        else:
          result.flags = result.flags or Options.fget(longOpt)
        longOpt = nil
      else:
        longOpt.add(c.toLower)
      continue
    # }}}

    result.flags = result.flags or Options.fget($c)
# }}}

type UncheckedArray {.unchecked.}[T] = array[0 .. 0, T]

proc destroyRegex(pattern: Regex) =
  pcre.free_substring(cast[cstring](pattern.pcreObj))
  pattern.pcreObj = nil
  if pattern.pcreExtra != nil:
    pcre.free_study(pattern.pcreExtra)

proc getNameToNumberTable(pattern: Regex): Table[string, int] =
  let entryCount = getinfo[cint](pattern, pcre.INFO_NAMECOUNT)
  let entrySize = getinfo[cint](pattern, pcre.INFO_NAMEENTRYSIZE)
  let table = cast[ptr UncheckedArray[uint8]](
                getinfo[int](pattern, pcre.INFO_NAMETABLE))

  result = initTable[string, int]()

  for i in 0 .. <entryCount:
    let pos = i * entrySize
    let num = (int(table[pos]) shl 8) or int(table[pos + 1]) - 1
    var name = ""

    var idx = 2
    while table[pos + idx] != 0:
      name.add(char(table[pos + idx]))
      idx += 1

    result[name] = num

proc initRegex(pattern: string, options: string): Regex =
  new(result, destroyRegex)
  result.pattern = pattern

  var errorMsg: cstring
  var errOffset: cint

  let opts = tokenizeOptions(options)

  result.pcreObj = pcre.compile(cstring(pattern),
                                # better hope int is at least 4 bytes..
                                cint(opts.flags), addr errorMsg,
                                addr errOffset, nil)
  if result.pcreObj == nil:
    # failed to compile
    raise SyntaxError(msg: $errorMsg, pos: errOffset, pattern: pattern)

  if opts.study:
    # XXX investigate JIT
    result.pcreExtra = pcre.study(result.pcreObj, 0x0, addr errorMsg)
    if errorMsg != nil:
      raise StudyError(msg: $errorMsg)

  result.captureNameToId = result.getNameToNumberTable()

proc re*(pattern: string, options = ""): Regex = initRegex(pattern, options)
# }}}

# Operations {{{
proc matchImpl(str: string, pattern: Regex, start, endpos: int, flags: int): RegexMatch =
  new(result)
  result.pattern = pattern
  result.str = str
  # See PCRE man pages.
  # 2x capture count to make room for start-end pairs
  # 1x capture count as slack space for PCRE
  let vecsize = (pattern.captureCount() + 1) * 3
  # div 2 because each element is 2 cints long
  result.pcreMatchBounds = newSeq[Slice[cint]](ceil(vecsize / 2).int)
  result.pcreMatchBounds.setLen(vecsize div 3)

  let strlen = if endpos == -1: str.len else: endpos

  let execRet = pcre.exec(pattern.pcreObj,
                          pattern.pcreExtra,
                          cstring(str),
                          cint(strlen),
                          cint(start),
                          cint(flags),
                          cast[ptr cint](addr result.pcreMatchBounds[0]),
                          cint(vecsize))
  if execRet >= 0:
    return result
  elif execRet == pcre.ERROR_NOMATCH:
    return nil
  else:
    raise newException(AssertionError, "Internal error: errno " & $execRet)

proc match*(str: string, pattern: Regex, start = 0, endpos = -1): RegexMatch =
  return str.matchImpl(pattern, start, endpos, pcre.ANCHORED)

iterator findIter*(str: string, pattern: Regex, start = 0, endpos = -1): RegexMatch =
  # see pcredemo for explaination
  let matchesCrLf = pattern.matchesCrLf()
  let unicode = bool(getinfo[cint](pattern, pcre.INFO_OPTIONS) and pcre.UTF8)
  let endpos = if endpos == -1: str.len else: endpos

  var offset = start
  var previousMatch: RegexMatch
  while true:
    var flags = 0

    if previousMatch != nil and
        previousMatch.matchBounds.a == previousMatch.matchBounds.b:
      # 0-len match
      flags = pcre.NOTEMPTY_ATSTART or pcre.ANCHORED

    let currentMatch = str.matchImpl(pattern, offset, endpos, flags)
    previousMatch = currentMatch

    if currentMatch == nil:
      # either the end of the input or the string
      # cannot be split here
      offset += 1

      if matchesCrLf and offset < (str.len - 1) and
         str[offset] == '\r' and str[offset + 1] == '\l':
        # if PCRE treats CrLf as newline, skip both at the same time
        offset += 1
      elif unicode:
        # XXX what about invalid unicode?
        offset += str.runeLenAt(offset)
        assert(offset <= endpos)
    else:
      offset = currentMatch.matchBounds.b

      yield currentMatch

    if offset >= endpos:
      # do while
      break

proc find*(str: string, pattern: Regex, start = 0, endpos = -1): RegexMatch =
  ## Returns a `RegexMatch` if there is a match between `start` and `endpos`, otherwise
  ## it returns nil.
  ##
  ## if `endpos == -1`, then `endpos = str.len`
  return str.matchImpl(pattern, start, endpos, 0)

proc findAll*(str: string, pattern: Regex, start = 0, endpos = -1): seq[string] =
  result = @[]
  for match in str.findIter(pattern, start, endpos):
    result.add(match.match)

proc renderBounds(str: string, bounds: Slice[int]): string =
  result = " " & str & "⫞\n"
  for i in -1 .. <bounds.a:
    result.add(" ")
  for i in bounds.a .. bounds.b:
    result.add("^")

proc split*(str: string, pattern: Regex, maxSplit = -1): seq[string] =
  result = @[]
  var lastIdx = 0
  var splits = 0
  var bounds: Slice[int]

  for match in str.findIter(pattern):
    # upper bound is exclusive, lower is inclusive:
    #
    # 0123456
    #  ^^^
    # (1, 4)
    bounds = match.matchBounds

    # "12".split("") would be @["", "1", "2"], but
    # if we skip an empty first match, it's the correct
    # @["1", "2"]
    if bounds.a < bounds.b or bounds.a > 0:
      result.add(str.substr(lastIdx, bounds.a - 1))
      splits += 1

    lastIdx = bounds.b

    for cap in match.captures:
      # if there are captures, include them in the result
      result.add(cap)

    if splits == maxSplit - 1:
      break

  # "12".split("\b") would be @["1", "2", ""], but
  # if we skip an empty last match, it's the correct
  # @["1", "2"]
  if bounds.a < bounds.b or bounds.b < str.len:
    # last match: Each match takes the previous substring,
    # but "1 2".split(/ /) needs to return @["1", "2"].
    # This handles "2"
    result.add(str.substr(bounds.b, str.len - 1))

template replaceImpl(str: string, pattern: Regex,
                     replacement: expr): stmt {.immediate, dirty.} =
  # XXX seems very similar to split, maybe I can reduce code duplication
  # somehow?
  result = ""
  var lastIdx = 0
  for match {.inject.} in str.findIter(pattern):
    let bounds = match.matchBounds
    result.add(str.substr(lastIdx, bounds.a - 1))
    let nextVal = replacement
    assert(nextVal != nil)
    result.add(nextVal)

    lastIdx = bounds.b

  result.add(str.substr(lastIdx, str.len - 1))
  return result

proc replace*(str: string, pattern: Regex,
              subproc: proc (match: RegexMatch): string): string =
  replaceImpl(str, pattern, subproc(match))

proc replace*(str: string, pattern: Regex, sub: string): string =
  # - 1 because the string numbers are 0-indexed
  replaceImpl(str, pattern,
    formatStr(sub, match.captures[name], match.captures[id - 1]))

# }}}

let SpecialCharMatcher = re"([\\+*?[^\]$(){}=!<>|:-])"
proc escapeRe*(str: string): string =
  str.replace(SpecialCharMatcher, "\\$1")
