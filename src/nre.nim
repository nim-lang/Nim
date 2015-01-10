import private.pcre as pcre
import private.util
import tables
import unsigned
from strutils import toLower, `%`

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

type
  Regex* = ref object
    pattern: string  # not nil
    pcreObj: ptr pcre.Pcre  # not nil
    pcreExtra: ptr pcre.ExtraData  ## nil

  RegexMatch* = object
    pattern: Regex
    matchBounds: Slice[int]

  SyntaxError* = ref object of Exception
    pos*: int  ## the location of the syntax error in bytes
    pattern*: string  ## the pattern that caused the problem

  StudyError* = ref object of Exception

# Creation & Destruction {{{
proc destroyRegex(self: Regex) =
  pcre.free_substring(cast[cstring](self.pcreObj))
  self.pcreObj = nil
  if self.pcreExtra != nil:
    pcre.free_study(self.pcreExtra)

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
    if result.pcreExtra == nil:
      raise StudyError(msg: $errorMsg)
# }}}

proc getinfo[T](self: Regex, opt: cint): T =
  let retcode = pcre.fullinfo(self.pcreObj, self.pcreExtra, opt, addr result)

  if retcode < 0:
    # XXX Error message that doesn't expose implementation details
    raise newException(FieldError, "Invalid getinfo for $1, errno $2" % [$opt, $retcode])

proc getCaptureCount(self: Regex): int =
  # get the maximum number of captures
  return getinfo[int](self, pcre.INFO_CAPTURECOUNT)

type UncheckedArray {.unchecked.}[T] = array[0 .. 0, T]
proc getNameToNumberTable(self: Regex): Table[string, int] =
  let entryCount = getinfo[cint](self, pcre.INFO_NAMECOUNT)
  let entrySize = getinfo[cint](self, pcre.INFO_NAMEENTRYSIZE)
  let table = cast[ptr UncheckedArray[uint8]](
                getinfo[int](self, pcre.INFO_NAMETABLE))

  result = initTable[string, int]()

  for i in 0 .. <entryCount:
    let pos = i * entrySize
    let num = (int(table[pos]) shl 8) or int(table[pos + 1])
    var name = ""

    var idx = 2
    while table[pos + idx] != 0:
      name.add(char(table[pos + idx]))
      idx += 1

    result[name] = num

proc exec*(self: Regex, str: string): RegexMatch =
  discard
