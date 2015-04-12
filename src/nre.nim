import private.pcre as pcre
import private.util
import tables
import unsigned
from future import lc, `[]`
from strutils import toLower, `%`
from math import ceil
import optional_t
from unicode import runeLenAt


## What is NRE?
## ============
##
## A regular expression library for Nim using PCRE to do the hard work.
##
## Why?
## ----
##
## The `re.nim <http://nim-lang.org/re.html>`__ module that
## `Nim <http://nim-lang.org/>`__ provides in its standard library is
## inadequate:
##
## -  It provides only a limited number of captures, while the underling
##    library (PCRE) allows an unlimited number.
##
## -  Instead of having one proc that returns both the bounds and
##    substring, it has one for the bounds and another for the substring.
##
## -  If the splitting regex is empty (``""``), then it returns the input
##    string instead of following `Perl <https://ideone.com/dDMjmz>`__,
##    `Javascript <http://jsfiddle.net/xtcbxurg/>`__, and
##    `Java <https://ideone.com/hYJuJ5>`__'s precedent of returning a list
##    of each character (``"123".split(re"") == @["1", "2", "3"]``).
##
##
## Other Notes
## -----------
##
## By default, NRE compiles it’s own PCRE. If this is undesirable, pass
## ``-d:pcreDynlib`` to use whatever dynamic library is available on the
## system. This may have unexpected consequences if the dynamic library
## doesn’t have certain features enabled.


# Type definitions {{{
type
  Regex* = ref object
    ## Represents the pattern that things are matched against, constructed with
    ## ``re(string, string)``. Examples: ``re"foo"``, ``re(r"foo # comment",
    ## "x<anycrlf>")``, ``re"(?x)(*ANYCRLF)foo # comment"``. For more details
    ## on the leading option groups, see the `Option
    ## Setting <http://man7.org/linux/man-pages/man3/pcresyntax.3.html#OPTION_SETTING>`__
    ## and the `Newline
    ## Convention <http://man7.org/linux/man-pages/man3/pcresyntax.3.html#NEWLINE_CONVENTION>`__
    ## sections of the `PCRE syntax
    ## manual <http://man7.org/linux/man-pages/man3/pcresyntax.3.html>`__.
    ##
    ## ``pattern: string``
    ##     the string that was used to create the pattern.
    ##
    ## ``captureCount: int``
    ##     the number of captures that the pattern has.
    ##
    ## ``captureNameId: Table[string, int]``
    ##     a table from the capture names to their numeric id.
    ##
    ##
    ## Flags
    ## .....
    ##
    ## -  ``8``, ``u``, ``<utf8>`` - treat both the pattern and subject as UTF8
    ## -  ``9``, ``<no_utf8>`` - prevents the pattern from being interpreted as UTF, no matter
    ##    what
    ## -  ``A``, ``<anchored>`` - as if the pattern had a ``^`` at the beginning
    ## -  ``E``, ``<dollar_endonly>`` - DOLLAR\_ENDONLY
    ## -  ``f``, ``<firstline>`` - fails if there is not a match on the first line
    ## -  ``i``, ``<case_insensitive>`` - case insensitive
    ## -  ``m``, ``<multiline>`` - multi-line, ``^`` and ``$`` match the beginning and end of
    ##    lines, not of the subject string
    ## -  ``N``, ``<no_auto_capture>`` - turn off auto-capture, ``(?foo)`` is necessary to capture.
    ## -  ``s``, ``<dotall>`` - ``.`` matches newline
    ## -  ``U``, ``<ungreedy>`` - expressions are not greedy by default. ``?`` can be added to
    ##    a qualifier to make it greedy.
    ## -  ``W``, ``<ucp>`` - Unicode character properties; ``\w`` matches ``к``.
    ## -  ``X``, ``<extra>`` - "Extra", character escapes without special meaning (``\w``
    ##    vs. ``\a``) are errors
    ## -  ``x``, ``<extended>`` - extended, comments (``#``) and newlines are ignored
    ##    (extended)
    ## -  ``Y``, ``<no_start_optimize>`` - pcre.NO\_START\_OPTIMIZE,
    ## -  ``<cr>`` - newlines are separated by ``\r``
    ## -  ``<crlf>`` - newlines are separated by ``\r\n`` (Windows default)
    ## -  ``<lf>`` - newlines are separated by ``\n`` (UNIX default)
    ## -  ``<anycrlf>`` - newlines are separated by any of the above
    ## -  ``<any>`` - newlines are separated by any of the above and Unicode
    ##    newlines:
    ##
    ##     single characters VT (vertical tab, U+000B), FF (form feed, U+000C),
    ##     NEL (next line, U+0085), LS (line separator, U+2028), and PS
    ##     (paragraph separator, U+2029). For the 8-bit library, the last two
    ##     are recognized only in UTF-8 mode.
    ##     —  man pcre
    ##
    ## -  ``<bsr_anycrlf>`` - ``\R`` matches CR, LF, or CRLF
    ## -  ``<bsr_unicode>`` - ``\R`` matches any unicode newline
    ## -  ``<js>`` - Javascript compatibility
    ## -  ``<no_study>`` - turn off studying; study is enabled by deafault
    pattern*: string  ## not nil
    pcreObj: ptr pcre.Pcre  ## not nil
    pcreExtra: ptr pcre.ExtraData  ## nil

    captureNameToId: Table[string, int]

  RegexMatch* = object
    ## Usually seen as Option[RegexMatch], it represents the result of an
    ## execution. On failure, it is ``None[RegexMatch]``, but if you want
    ## automated derefrence, import ``optional_t.nonstrict``. The available
    ## fields are as follows:
    ##
    ## ``pattern: Regex``
    ##     the pattern that is being matched
    ##
    ## ``str: string``
    ##     the string that was matched against
    ##
    ## ``captures[]: string``
    ##     the string value of whatever was captured at that id. If the value
    ##     is invalid, then behavior is undefined. If the id is ``-1``, then
    ##     the whole match is returned. If the given capture was not matched,
    ##     ``nil`` is returned.
    ##
    ##     -  ``"abc".match(re"(\w)").captures[0] == "a"``
    ##     -  ``"abc".match(re"(?<letter>\w)").captures["letter"] == "a"``
    ##     -  ``"abc".match(re"(\w)\w").captures[-1] == "ab"``
    ##
    ## ``captureBounds[]: Option[Slice[int]]``
    ##     gets the bounds of the given capture according to the same rules as
    ##     the above. If the capture is not filled, then ``None`` is returned.
    ##     The bounds are both inclusive.
    ##
    ##     -  ``"abc".match(re"(\w)").captureBounds[0] == 0 .. 0``
    ##     -  ``"abc".match(re"").captureBounds[-1] == 0 .. -1``
    ##     -  ``"abc".match(re"abc").captureBounds[-1] == 0 .. 2``
    ##
    ## ``match: string``
    ##     the full text of the match.
    ##
    ## ``matchBounds: Slice[int]``
    ##     the bounds of the match, as in ``captureBounds[]``
    ##
    ## ``(captureBounds|captures).toTable``
    ##     returns a table with each named capture as a key.
    ##
    ## ``(captureBounds|captures).toSeq``
    ##     returns all the captures by their number.
    ##
    ## ``$: string``
    ##     same as ``match``
    pattern*: Regex  ## The regex doing the matching.
                     ## Not nil.
    str*: string  ## The string that was matched against.
                  ## Not nil.
    pcreMatchBounds: seq[Slice[cint]] ## First item is the bounds of the match
                                      ## Other items are the captures
                                      ## `a` is inclusive start, `b` is exclusive end

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
  return getinfo[cint](pattern, pcre.INFO_CAPTURECOUNT)

proc captureNameId*(pattern: Regex): Table[string, int] =
  return pattern.captureNameToId

proc matchesCrLf(pattern: Regex): bool =
  let flags = uint32(getinfo[culong](pattern, pcre.INFO_OPTIONS))
  let newlineFlags = flags and (pcre.NEWLINE_CRLF or
                                pcre.NEWLINE_ANY or
                                pcre.NEWLINE_ANYCRLF)
  if newLineFlags > 0u32:
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
  let pattern = RegexMatch(pattern)
  if pattern.pcreMatchBounds[i + 1].a != -1:
    let bounds = pattern.pcreMatchBounds[i + 1]
    return Some(int(bounds.a) .. int(bounds.b-1))
  else:
    return None[Slice[int]]()

proc `[]`*(pattern: Captures, i: int): string =
  let pattern = RegexMatch(pattern)
  let bounds = pattern.captureBounds[i]

  if bounds:
    let bounds = bounds.get
    return pattern.str.substr(bounds.a, bounds.b)
  else:
    return nil

proc match*(pattern: RegexMatch): string =
  return pattern.captures[-1]

proc matchBounds*(pattern: RegexMatch): Slice[int] =
  return pattern.captureBounds[-1].get

proc `[]`*(pattern: CaptureBounds, name: string): Option[Slice[int]] =
  let pattern = RegexMatch(pattern)
  return pattern.captureBounds[pattern.pattern.captureNameToId.fget(name)]

proc `[]`*(pattern: Captures, name: string): string =
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
  result = initTable[string, string]()
  toTableImpl(nextVal == nil)

proc toTable*(pattern: CaptureBounds, default = None[Slice[int]]()):
    Table[string, Option[Slice[int]]] =
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

proc `==`*(a, b: Regex): bool =
  if not a.isNil and not b.isNil:
    return a.pattern   == b.pattern and
           a.pcreObj   == b.pcreObj and
           a.pcreExtra == b.pcreExtra
  else:
    return system.`==`(a, b)

proc `==`*(a, b: RegexMatch): bool =
  return a.pattern == b.pattern and
         a.str     == b.str
# }}}

# Creation & Destruction {{{
# PCRE Options {{{
let Options: Table[string, int] = {
  "8" : pcre.UTF8,
  "utf8" : pcre.UTF8,
  "9" : pcre.NEVER_UTF,
  "no_utf8" : pcre.NEVER_UTF,
  "A" : pcre.ANCHORED,
  "anchored" : pcre.ANCHORED,
  # "C" : pcre.AUTO_CALLOUT, unsuported XXX
  "E" : pcre.DOLLAR_ENDONLY,
  "dollar_endonly" : pcre.DOLLAR_ENDONLY,
  "f" : pcre.FIRSTLINE,
  "firstline" : pcre.FIRSTLINE,
  "i" : pcre.CASELESS,
  "case_insensitive" : pcre.CASELESS,
  "m" : pcre.MULTILINE,
  "multiline" : pcre.MULTILINE,
  "N" : pcre.NO_AUTO_CAPTURE,
  "no_auto_capture" : pcre.NO_AUTO_CAPTURE,
  "s" : pcre.DOTALL,
  "dotall" : pcre.DOTALL,
  "U" : pcre.UNGREEDY,
  "ungreedy" : pcre.UNGREEDY,
  "u" : pcre.UTF8,
  "W" : pcre.UCP,
  "ucp" : pcre.UCP,
  "X" : pcre.EXTRA,
  "extra" : pcre.EXTRA,
  "x" : pcre.EXTENDED,
  "extended" : pcre.EXTENDED,
  "Y" : pcre.NO_START_OPTIMIZE,
  "no_start_optimize" : pcre.NO_START_OPTIMIZE,

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
proc matchImpl(str: string, pattern: Regex, start, endpos: int, flags: int): Option[RegexMatch] =
  var myResult = RegexMatch(pattern : pattern, str : str)
  # See PCRE man pages.
  # 2x capture count to make room for start-end pairs
  # 1x capture count as slack space for PCRE
  let vecsize = (pattern.captureCount() + 1) * 3
  # div 2 because each element is 2 cints long
  myResult.pcreMatchBounds = newSeq[Slice[cint]](ceil(vecsize / 2).int)
  myResult.pcreMatchBounds.setLen(vecsize div 3)

  let strlen = if endpos == int.high: str.len else: endpos+1
  doAssert(strlen <= str.len)  # don't want buffer overflows

  let execRet = pcre.exec(pattern.pcreObj,
                          pattern.pcreExtra,
                          cstring(str),
                          cint(strlen),
                          cint(start),
                          cint(flags),
                          cast[ptr cint](addr myResult.pcreMatchBounds[0]),
                          cint(vecsize))
  if execRet >= 0:
    return Some(myResult)
  elif execRet == pcre.ERROR_NOMATCH:
    return None[RegexMatch]()
  else:
    raise newException(AssertionError, "Internal error: errno " & $execRet)

proc match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  ## Like ```find(...)`` <#proc-find>`__, but anchored to the start of the
  ## string. This means that ``"foo".match(re"f") == true``, but
  ## ``"foo".match(re"o") == false``.
  return str.matchImpl(pattern, start, endpos, pcre.ANCHORED)

iterator findIter*(str: string, pattern: Regex, start = 0, endpos = int.high): RegexMatch =
  ## Works the same as ```find(...)`` <#proc-find>`__, but finds every
  ## non-overlapping match. ``"2222".find(re"22")`` is ``"22", "22"``, not
  ## ``"22", "22", "22"``.
  ##
  ## Arguments are the same as ```find(...)`` <#proc-find>`__
  ##
  ## Variants:
  ##
  ## -  ``proc findAll(...)`` returns a ``seq[string]``
  # see pcredemo for explaination
  let matchesCrLf = pattern.matchesCrLf()
  let unicode = uint32(getinfo[culong](pattern, pcre.INFO_OPTIONS) and
    pcre.UTF8) > 0u32
  let strlen = if endpos == int.high: str.len else: endpos+1

  var offset = start
  var match: Option[RegexMatch]
  while true:
    var flags = 0

    if match and
       match.get.matchBounds.a > match.get.matchBounds.b:
      # 0-len match
      flags = pcre.NOTEMPTY_ATSTART or pcre.ANCHORED

    match = str.matchImpl(pattern, offset, endpos, flags)

    if match.isNone:
      # either the end of the input or the string
      # cannot be split here
      if offset >= strlen:
        break

      if matchesCrLf and offset < (str.len - 1) and
         str[offset] == '\r' and str[offset + 1] == '\l':
        # if PCRE treats CrLf as newline, skip both at the same time
        offset += 2
      elif unicode:
        # XXX what about invalid unicode?
        offset += str.runeLenAt(offset)
        assert(offset <= strlen)
      else:
        offset += 1
    else:
      offset = match.get.matchBounds.b + 1

      yield match.get


proc find*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch] =
  ## Finds the given pattern in the string between the end and start
  ## positions.
  ##
  ## ``start``
  ##     The start point at which to start matching. ``|abc`` is ``0``;
  ##     ``a|bc`` is ``1``
  ##
  ## ``endpos``
  ##     The maximum index for a match; ``int.high`` means the end of the
  ##     string, otherwise it’s an inclusive upper bound.
  return str.matchImpl(pattern, start, endpos, 0)

proc findAll*(str: string, pattern: Regex, start = 0, endpos = int.high): seq[string] =
  result = @[]
  for match in str.findIter(pattern, start, endpos):
    result.add(match.match)

proc split*(str: string, pattern: Regex, maxSplit = -1, start = 0): seq[string] =
  ## Splits the string with the given regex. This works according to the
  ## rules that Perl and Javascript use:
  ##
  ## -  If the match is zero-width, then the string is still split:
  ##    ``"123".split(r"") == @["1", "2", "3"]``.
  ##
  ## -  If the pattern has a capture in it, it is added after the string
  ##    split: ``"12".split(re"(\d)") == @["", "1", "", "2", ""]``.
  ##
  ## -  If ``maxsplit != -1``, then the string will only be split
  ##    ``maxsplit - 1`` times. This means that there will be ``maxsplit``
  ##    strings in the output seq.
  ##    ``"1.2.3".split(re"\.", maxsplit = 2) == @["1", "2.3"]``
  ##
  ## ``start`` behaves the same as in ```find(...)`` <#proc-find>`__.
  result = @[]
  var lastIdx = start
  var splits = 0
  var bounds = 0 .. 0

  for match in str.findIter(pattern, start = start):
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
      result.add(cap)

    if splits == maxSplit - 1:
      break

  # "12".split("\b") would be @["1", "2", ""], but
  # if we skip an empty last match, it's the correct
  # @["1", "2"]
  if bounds.a <= bounds.b or bounds.b < str.high:
    # last match: Each match takes the previous substring,
    # but "1 2".split(/ /) needs to return @["1", "2"].
    # This handles "2"
    result.add(str.substr(bounds.b + 1, str.high))

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

    lastIdx = bounds.b + 1

  result.add(str.substr(lastIdx, str.len - 1))
  return result

proc replace*(str: string, pattern: Regex,
              subproc: proc (match: RegexMatch): string): string =
  ## Replaces each match of Regex in the string with ``sub``, which should
  ## never be or return ``nil``.
  ##
  ## If ``sub`` is a ``proc (RegexMatch): string``, then it is executed with
  ## each match and the return value is the replacement value.
  ##
  ## If ``sub`` is a ``proc (string): string``, then it is executed with the
  ## full text of the match and and the return value is the replacement
  ## value.
  ##
  ## If ``sub`` is a string, the syntax is as follows:
  ##
  ## -  ``$$`` - literal ``$``
  ## -  ``$123`` - capture number ``123``
  ## -  ``$foo`` - named capture ``foo``
  ## -  ``${foo}`` - same as above
  ## -  ``$1$#`` - first and second captures
  ## -  ``$#`` - first capture
  ## -  ``$0`` - full match
  ##
  ## If a given capture is missing, a ``ValueError`` exception is thrown.
  replaceImpl(str, pattern, subproc(match))

proc replace*(str: string, pattern: Regex,
              subproc: proc (match: string): string): string =
  replaceImpl(str, pattern, subproc(match.match))

proc replace*(str: string, pattern: Regex, sub: string): string =
  # - 1 because the string numbers are 0-indexed
  replaceImpl(str, pattern,
    formatStr(sub, match.captures[name], match.captures[id - 1]))

# }}}

let SpecialCharMatcher = re"([\\+*?[^\]$(){}=!<>|:-])"
proc escapeRe*(str: string): string =
  ## Escapes the string so it doesn’t match any special characters.
  ## Incompatible with the Extra flag (``X``).
  str.replace(SpecialCharMatcher, "\\$1")
