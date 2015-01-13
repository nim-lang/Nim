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
    pattern*: string  # not nil
    pcreObj: ptr pcre.Pcre  # not nil
    pcreExtra: ptr pcre.ExtraData  ## nil

    captureNameToId: Table[string, int]

  RegexMatch* = ref object
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
    pos*: int  ## the location of the syntax error in bytes
    pattern*: string  ## the pattern that caused the problem

  StudyError* = ref object of Exception
# }}}

proc getinfo[T](self: Regex, opt: cint): T =
  let retcode = pcre.fullinfo(self.pcreObj, self.pcreExtra, opt, addr result)

  if retcode < 0:
    # XXX Error message that doesn't expose implementation details
    raise newException(FieldError, "Invalid getinfo for $1, errno $2" % [$opt, $retcode])

# Regex accessors {{{
proc captureCount*(self: Regex): int =
  ## Get the maximum number of captures
  ##
  ## Does not return the number of captured captures
  return getinfo[int](self, pcre.INFO_CAPTURECOUNT)

proc captureNameId*(self: Regex): Table[string, int] =
  ## Returns a map from named capture groups to their numerical
  ## identifier
  return self.captureNameToId

proc matchesCrLf(self: Regex): bool =
  let flags = getinfo[cint](self, pcre.INFO_OPTIONS)
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
proc captureBounds*(self: RegexMatch): CaptureBounds = return CaptureBounds(self)

proc captures*(self: RegexMatch): Captures = return Captures(self)

proc `[]`*(self: CaptureBounds, i: int): Option[Slice[int]] =
  ## Gets the bounds of the `i`th capture.
  ## Undefined behavior if `i` is out of bounds
  ## If `i` is a failed optional capture, returns None
  ## If `i == -1`, returns the whole match
  let self = RegexMatch(self)
  if self.pcreMatchBounds[i + 1].a != -1:
    let bounds = self.pcreMatchBounds[i + 1]
    return Some(int(bounds.a) .. int(bounds.b))
  else:
    return None[Slice[int]]()

proc `[]`*(self: Captures, i: int): string =
  ## gets the `i`th capture
  ## Undefined behavior if `i` is out of bounds
  ## If `i` is a failed optional capture, returns nil
  ## If `i == -1`, returns the whole match
  let self = RegexMatch(self)
  let bounds = self.captureBounds[i]

  if bounds:
    let bounds = bounds.get
    if self.matchCache == nil:
      # capture count, plus the entire string
      self.matchCache = newSeq[string](self.pattern.captureCount + 1)
    if self.matchCache[i + 1] == nil:
      self.matchCache[i + 1] = self.str[bounds.a .. bounds.b-1]
    return self.matchCache[i + 1]
  else:
    return nil

proc match*(self: RegexMatch): string =
  return self.captures[-1]

proc matchBounds*(self: RegexMatch): Slice[int] =
  return self.captureBounds[-1].get

proc `[]`*(self: CaptureBounds, name: string): Option[Slice[int]] =
  ## Will fail with KeyError if `name` is not a real named capture
  let self = RegexMatch(self)
  return self.captureBounds[self.pattern.captureNameToId.fget(name)]

proc `[]`*(self: Captures, name: string): string =
  ## Will fail with KeyError if `name` is not a real named capture
  let self = RegexMatch(self)
  return self.captures[self.pattern.captureNameToId.fget(name)]

template asTableImpl(cond: bool): stmt {.immediate, dirty.} =
  for key in RegexMatch(self).pattern.captureNameId.keys:
    let nextVal = self[key]
    if cond:
      result[key] = default
    else:
      result[key] = nextVal

proc asTable*(self: Captures, default: string = nil): Table[string, string] =
  ## Gets all the named captures and returns them
  result = initTable[string, string]()
  asTableImpl(nextVal == nil)

proc asTable*(self: CaptureBounds, default = None[Slice[int]]()):
    Table[string, Option[Slice[int]]] =
  ## Gets all the named captures and returns them
  result = initTable[string, Option[Slice[int]]]()
  asTableImpl(nextVal.isNone)

template asSeqImpl(cond: bool): stmt {.immediate, dirty.} =
  result = @[]
  for i in 0 .. <RegexMatch(self).pattern.captureCount:
    let nextVal = self[i]
    if cond:
      result.add(default)
    else:
      result.add(nextVal)

proc asSeq*(self: CaptureBounds, default = None[Slice[int]]()): seq[Option[Slice[int]]] =
  asSeqImpl(nextVal.isNone)

proc asSeq*(self: Captures, default: string = nil): seq[string] =
  asSeqImpl(nextVal == nil)
# }}}

# Creation & Destruction {{{
# PCRE Options {{{
let Options: Table[string, int] = {
  "8" : pcre.UTF8,
  "9" : pcre.NEVER_UTF,
  "?" : pcre.NO_UTF8_CHECK,
  "A" : pcre.ANCHORED,
  # "C" : pcre.AUTO_CALLOUT, unsuported XXX
  "E" : pcre.DOLLAR_ENDONLY,
  "f" : pcre.FIRSTLINE,
  "i" : pcre.CASELESS,
  "m" : pcre.MULTILINE,
  "N" : pcre.NO_AUTO_CAPTURE,
  "O" : pcre.NO_AUTO_POSSESS,
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
  result = (0, false)

  var longOpt: string = nil
  for i, c in opts:
    # Handle long options {{{
    if c == '<':
      longOpt = ""
      continue

    if longOpt != nil:
      if c == '>':
        result.flags = result.flags or Options.fget(longOpt)
        longOpt = nil
      else:
        longOpt.add(c.toLower)
      continue
    # }}}

    if c == 'S':  # handle study
      result.study = true
      continue

    result.flags = result.flags or Options.fget($c)
# }}}

type UncheckedArray {.unchecked.}[T] = array[0 .. 0, T]

proc destroyRegex(self: Regex) =
  pcre.free_substring(cast[cstring](self.pcreObj))
  self.pcreObj = nil
  if self.pcreExtra != nil:
    pcre.free_study(self.pcreExtra)

proc getNameToNumberTable(self: Regex): Table[string, int] =
  let entryCount = getinfo[cint](self, pcre.INFO_NAMECOUNT)
  let entrySize = getinfo[cint](self, pcre.INFO_NAMEENTRYSIZE)
  let table = cast[ptr UncheckedArray[uint8]](
                getinfo[int](self, pcre.INFO_NAMETABLE))

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

proc initRegex*(pattern: string, options = "Sx"): Regex =
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
# }}}

proc matchImpl*(self: Regex, str: string, start, endpos: int, flags: int): Option[RegexMatch] =
  var result: RegexMatch
  new(result)
  result.pattern = self
  result.str = str
  # See PCRE man pages.
  # 2x capture count to make room for start-end pairs
  # 1x capture count as slack space for PCRE
  let vecsize = (self.captureCount() + 1) * 3
  # div 2 because each element is 2 cints long
  result.pcreMatchBounds = newSeq[Slice[cint]](ceil(vecsize / 2).int)
  result.pcreMatchBounds.setLen(vecsize div 3)

  let execRet = pcre.exec(self.pcreObj,
                          self.pcreExtra,
                          cstring(str),
                          cint(max(str.len, endpos)),
                          cint(start),
                          cint(flags),
                          cast[ptr cint](addr result.pcreMatchBounds[0]),
                          cint(vecsize))
  if execRet >= 0:
    return Some(result)
  elif execRet == pcre.ERROR_NOMATCH:
    return None[RegexMatch]()
  else:
    raise newException(AssertionError, "Internal error: errno " & $execRet)

proc match*(self: Regex, str: string, start = 0, endpos = -1): Option[RegexMatch] =
  ## Returns Some if there is a match between `start` and `endpos`, otherwise
  ## it returns None.
  ##
  ## if `endpos == -1`, then `endpos = str.len`
  return matchImpl(self, str, start, endpos, 0)

iterator findIter*(self: Regex, str: string, start = 0, endpos = -1): RegexMatch =
  # see pcredemo for explaination
  let matchesCrLf = self.matchesCrLf()
  let unicode = bool(getinfo[cint](self, pcre.INFO_OPTIONS) and pcre.UTF8)
  let endpos = if endpos == -1: str.len else: endpos

  var offset = start
  var previousMatch: RegexMatch
  while offset != endpos:
    if offset > endpos:
      # eos occurs in the middle of a unicode char? die.
      raise newException(AssertionError, "Input string has malformed unicode")

    var flags = 0

    if previousMatch != nil and
        previousMatch.matchBounds.a == previousMatch.matchBounds.b:
      # 0-len match
      flags = pcre.NOTEMPTY_ATSTART or pcre.ANCHORED

    let currentMatch = self.matchImpl(str, offset, endpos, flags)
    previousMatch = currentMatch.get(nil)

    if currentMatch.isNone:
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
    else:
      let currentMatch = currentMatch.get
      offset = currentMatch.matchBounds.b

      yield currentMatch

proc find*(self: Regex, str: string, start = 0, endpos = -1): Option[RegexMatch] =
  for match in self.findIter(str, start, endpos):
    return Some(match)

  return None[RegexMatch]()

proc findAll*(self: Regex, str: string, start = 0, endpos = -1): seq[RegexMatch] =
  accumulateResult(self.findIter(str, start, endpos))

proc renderBounds(str: string, bounds: Slice[int]): string =
  result = " " & str & "⫞\n"
  for i in -1 .. <bounds.a:
    result.add(" ")
  for i in bounds.a .. bounds.b:
    result.add("^")

proc split*(self: Regex, str: string): seq[string] =
  result = @[]
  var lastIdx = 0

  for match in self.findIter(str):
    # upper bound is exclusive, lower is inclusive:
    #
    # 0123456
    #  ^^^
    # (1, 4)
    var bounds = match.matchBounds

    if lastIdx == 0 and
       lastIdx == bounds.a and
       bounds.a == bounds.b:
      # "12".split("") would be @["", "1", "2"], but
      # if we skip an empty first match, it's the correct
      # @["1", "2"]
      discard
    else:
      result.add(str.substr(lastIdx, bounds.a - 1))

    lastIdx = bounds.b

  # last match: Each match takes the previous substring,
  # but "1 2".split(/ /) needs to return @["1", "2"].
  # This handles "2"
  result.add(str.substr(lastIdx, str.len - 1))
