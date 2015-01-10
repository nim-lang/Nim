import private.pcre as pcre
import private.util
import tables
import unsigned
from strutils import toLower

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
  "J" : pcre.DUPNAMES,
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

proc initRegex*(pattern: string, options = "Sx"): Regex =
  new result
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
