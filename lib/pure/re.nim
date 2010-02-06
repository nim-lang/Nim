#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Regular expression support for Nimrod. Consider using the pegs module
## instead.
## Currently this module is implemented by providing a wrapper around the
## `PRCE (Perl-Compatible Regular Expressions) <http://www.pcre.org>`_
## C library. This means that your application will depend on the PRCE
## library's licence when using this module, which should not be a problem
## though.
## PRCE's licence follows:
##
## .. include:: ../doc/regexprs.txt
##

import
  pcre, strutils

const
  MaxSubpatterns* = 10
    ## defines the maximum number of subpatterns that can be captured.
    ## More subpatterns cannot be captured!

type
  TRegExOptions* = enum  ## options for regular expressions
    reIgnoreCase = 0,    ## do caseless matching
    reMultiLine = 1,     ## ``^`` and ``$`` match newlines within data 
    reDotAll = 2,        ## ``.`` matches anything including NL
    reExtended = 3,      ## ignore whitespace and ``#`` comments
    
    
    PCRE_ANCHORED* = 0x00000010
    PCRE_DOLLAR_ENDONLY* = 0x00000020
    PCRE_EXTRA* = 0x00000040
    PCRE_NOTBOL* = 0x00000080
    PCRE_NOTEOL* = 0x00000100
    PCRE_UNGREEDY* = 0x00000200
    PCRE_NOTEMPTY* = 0x00000400
    PCRE_UTF8* = 0x00000800
    PCRE_NO_AUTO_CAPTURE* = 0x00001000
    
    
  TRegExDesc {.pure, final.}  = object 
    h: PPcre
    
  TRegEx* = ref TRegExDesc ## a compiled regular expression
    
  EInvalidRegEx* = object of EInvalidValue
    ## is raised if the pattern is no valid regular expression.

proc rawCompile(pattern: string, flags: cint): PPcre =
  var
    msg: CString
    offset: int
    com = pcreCompile(pattern, flags, addr(msg), addr(offset), nil)
  if com == nil:
    var e: ref EInvalidRegEx
    new(e)
    e.msg = $msg & "\n" & pattern & "\n" & repeatChar(offset) & "^\n"
    raise e
  return com

proc finalizeRegEx(x: TRegEx) = dealloc(x.h)

proc re*(s: string): TRegEx =
  ## Constructor of regular expressions. Note that Nimrod's
  ## extended raw string literals supports this syntax ``re"[abc]"`` as
  ## a short form for ``re(r"[abc]")``.
  new(result, finalizeRegEx)
  result.h = rawCompile(s, 
  
  var err = int(regncomp(addr(result^), s, s.len,
                cint(REG_EXTENDED or REG_NEWLINE)))
  if err != 0:
    var e: ref EInvalidRegEx
    new(e)
    e.msg = ErrorMessages[err]
    raise e

proc xre*(pattern: string): TRegEx = 
  ## deletes whitespace from a pattern that is not escaped or in a character
  ## class. Then it constructs a regular expresion object via `re`.
  ## This is modelled after Perl's ``/x`` modifier. 
  var p = ""
  var i = 0
  while i < pattern.len: 
    case pattern[i]
    of ' ', '\t': 
      inc i
    of '\\': 
      add p, '\\'
      add p, pattern[i+1]
      inc i, 2
    of '[': 
      while pattern[i] != ']' and pattern[i] != '\0': 
        add p, pattern[i]
        inc i
    else: 
      add p, pattern[i]
      inc i
  result = re(p)

proc matchOrFind(s: string, pattern: PPcre, matches: var openarray[string],
                 start: cint): cint =
  var
    rawMatches: array [0..maxSubpatterns * 3 - 1, cint]
    res = int(pcreExec(pattern, nil, s, len(s), start, 0,
      cast[ptr cint](addr(rawMatches)), maxSubpatterns * 3))
  dealloc(pattern)
  if res < 0: return res
  for i in 0..res-1:
    var
      a = rawMatches[i * 2]
      b = rawMatches[i * 2 + 1]
    if a >= 0'i32: matches[i] = copy(s, a, int(b)-1)
    else: matches[i] = ""
  return res

proc matchOrFind(s: string, pattern: PPcre, start: cint): cint =
  var
    rawMatches: array [0..maxSubpatterns * 3 - 1, cint]
    res = pcreExec(pattern, nil, s, len(s), start, 0,
                   cast[ptr cint](addr(rawMatches)), maxSubpatterns * 3)
  dealloc(pattern)
  return res

proc match(s, pattern: string, matches: var openarray[string],
           start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED),
                     matches, start) >= 0'i32

proc matchLen(s, pattern: string, matches: var openarray[string],
              start: int = 0): int =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED), matches, start)

proc find(s, pattern: string, matches: var openarray[string],
          start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_MULTILINE),
                     matches, start) >= 0'i32

proc match(s, pattern: string, start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED), start) >= 0'i32

proc find(s, pattern: string, start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_MULTILINE), start) >= 0'i32

template `=~` *(s, pattern: expr): expr = 
  ## This calls ``match`` with an implicit declared ``matches`` array that 
  ## can be used in the scope of the ``=~`` call: 
  ## 
  ## .. code-block:: nimrod
  ##
  ##   if line =~ r"\s*(\w+)\s*\=\s*(\w+)": 
  ##     # matches a key=value pair:
  ##     echo("Key: ", matches[1])
  ##     echo("Value: ", matches[2])
  ##   elif line =~ r"\s*(\#.*)":
  ##     # matches a comment
  ##     # note that the implicit ``matches`` array is different from the
  ##     # ``matches`` array of the first branch
  ##     echo("comment: ", matches[1])
  ##   else:
  ##     echo("syntax error")
  ##
  when not definedInScope(matches):
    var matches: array[0..maxSubPatterns-1, string]
  match(s, pattern, matches)



proc regnexec(preg: ptr TRegExDesc, s: cstring, len, nmatch: int,
              pmatch: ptr array [0..maxSubpatterns-1, TRegMatch],
              eflags: cint): cint {.importc.}
proc regncomp(preg: ptr TRegExDesc, regex: cstring, n: int,
              cflags: cint): cint {.importc.}
proc regfree(preg: ptr TRegExDesc) {.importc.}

const
  # POSIX regcomp() flags
  REG_EXTENDED = 1
  REG_ICASE = (REG_EXTENDED shl 1)
  REG_NEWLINE = (REG_ICASE shl 1)
  REG_NOSUB = (REG_NEWLINE shl 1)
  # Extra regcomp() flags
  REG_BASIC = 0
  REG_LITERAL = (REG_NOSUB shl 1)
  REG_RIGHT_ASSOC = (REG_LITERAL shl 1)
  REG_UNGREEDY = (REG_RIGHT_ASSOC shl 1)

  # POSIX regexec() flags
  REG_NOTBOL = 1
  REG_NOTEOL = (REG_NOTBOL shl 1)

  # Extra regexec() flags
  REG_APPROX_MATCHER = (REG_NOTEOL shl 1)
  REG_BACKTRACKING_MATCHER = (REG_APPROX_MATCHER shl 1)

  ErrorMessages = [
    "No error",
    "No match",
    "Invalid regexp",
    "Unknown collating element",
    "Unknown character class name",
    "Trailing backslash",
    "Invalid back reference",
    "Missing ']'",
    "Missing ')'",
    "Missing '}'",
    "Invalid contents of {}",
    "Invalid character range",
    "Out of memory",
    "Invalid use of repetition operators"
  ]

proc rawmatch(s: string, pattern: TRegEx, matches: var openarray[string],
              start: int): tuple[first, last: int] =
  var
    rawMatches: array [0..maxSubpatterns-1, TRegMatch]
    cs = cstring(s)
    res = int(regnexec(addr(pattern^), cast[cstring](addr(cs[start])),
              s.len-start, maxSubpatterns, addr(rawMatches), cint(0)))
  if res == 0:
    for i in 0..min(matches.len, int(pattern.re_nsub))-1:
      var a = int(rawMatches[i].so)
      var b = int(rawMatches[i].eo)
      echo "a: ", a, " b: ", b
      if a >= 0 and b >= 0:
        matches[i] = copy(s, a+start, b - 1 + start)
      else:
        matches[i] = ""
    return (int(rawMatches[0].so), int(rawMatches[0].eo)-1)
  return (-1, -1)

proc match*(s: string, pattern: TRegEx, matches: var openarray[string],
            start = 0): bool =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  result = rawmatch(s, pattern, matches, start).first == 0

proc match*(s: string, pattern: TRegEx, start: int = 0): bool =
  ## returns ``true`` if ``s`` matches the ``pattern`` beginning
  ## from ``start``.
  var matches: array [0..0, string]
  result = rawmatch(s, pattern, matches, start).first == 0

proc matchLen*(s: string, pattern: TRegEx, matches: var openarray[string],
               start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.
  var (a, b) = rawmatch(s, pattern, matches, start)
  result = a - b + 1

proc matchLen*(s: string, pattern: TRegEx, start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.
  var matches: array [0..0, string]
  var (a, b) = rawmatch(s, pattern, matches, start)
  result = a - b + 1

proc find*(s: string, pattern: TRegEx, matches: var openarray[string],
           start = 0): int =
  ## returns ``true`` if ``pattern`` occurs in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches``.
  result = rawmatch(s, pattern, matches, start).first
  if result >= 0: inc(result, start)

proc find*(s: string, pattern: TRegEx, start = 0): int =
  ## returns ``true`` if ``pattern`` occurs in ``s``.
  var matches: array [0..0, string]
  result = rawmatch(s, pattern, matches, start).first
  if result >= 0: inc(result, start)

template `=~`*(s: string, pattern: TRegEx): expr = 
  ## This calls ``match`` with an implicit declared ``matches`` array that 
  ## can be used in the scope of the ``=~`` call: 
  ## 
  ## .. code-block:: nimrod
  ##
  ##   if line =~ r"\s*(\w+)\s*\=\s*(\w+)": 
  ##     # matches a key=value pair:
  ##     echo("Key: ", matches[1])
  ##     echo("Value: ", matches[2])
  ##   elif line =~ r"\s*(\#.*)":
  ##     # matches a comment
  ##     # note that the implicit ``matches`` array is different from the
  ##     # ``matches`` array of the first branch
  ##     echo("comment: ", matches[1])
  ##   else:
  ##     echo("syntax error")
  ##
  when not definedInScope(matches):
    var matches: array[0..maxSubPatterns-1, string]
  match(s, pattern, matches)
  
# ------------------------- more string handling ------------------------------

proc contains*(s: string, pattern: TRegEx, start = 0): bool =
  ## same as ``find(s, pattern, start) >= 0``
  return find(s, pattern, start) >= 0

proc contains*(s: string, pattern: TRegEx, matches: var openArray[string],
              start = 0): bool =
  ## same as ``find(s, pattern, matches, start) >= 0``
  return find(s, pattern, matches, start) >= 0

proc startsWith*(s: string, prefix: TRegEx): bool =
  ## returns true if `s` starts with the pattern `prefix`
  result = matchLen(s, prefix) >= 0

proc endsWith*(s: string, suffix: TRegEx): bool =
  ## returns true if `s` ends with the pattern `prefix`
  for i in 0 .. s.len-1:
    if matchLen(s, suffix, i) == s.len - i: return true

proc replace*(s: string, sub: TRegEx, by: string): string =
  ## Replaces `sub` in `s` by the string `by`. Captures can be accessed in `by`
  ## with the notation ``$i`` and ``$#`` (see strutils.`%`). Examples:
  ##
  ## .. code-block:: nimrod
  ##   "var1=key; var2=key2".replace(re"(\w+)'='(\w+)", "$1<-$2$2")
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##
  ##   "var1<-keykey; val2<-key2key2"
  result = ""
  var i = 0
  var caps: array[0..maxSubpatterns-1, string]
  while i < s.len:
    var x = matchLen(s, sub, caps, i)
    if x <= 0:
      add(result, s[i])
      inc(i)
    else:
      addf(result, by, caps)
      inc(i, x)
  # copy the rest:
  add(result, copy(s, i))
  
proc parallelReplace*(s: string, subs: openArray[
                      tuple[pattern: TRegEx, repl: string]]): string = 
  ## Returns a modified copy of `s` with the substitutions in `subs`
  ## applied in parallel.
  result = ""
  var i = 0
  var caps: array[0..maxSubpatterns-1, string]
  while i < s.len:
    block searchSubs:
      for j in 0..high(subs):
        var x = matchLen(s, subs[j][0], caps, i)
        if x > 0:
          addf(result, subs[j][1], caps)
          inc(i, x)
          break searchSubs
      add(result, s[i])
      inc(i)
  # copy the rest:
  add(result, copy(s, i))  
  
proc transformFile*(infile, outfile: string,
                    subs: openArray[tuple[pattern: TRegEx, repl: string]]) =
  ## reads in the file `infile`, performs a parallel replacement (calls
  ## `parallelReplace`) and writes back to `outfile`. Calls ``quit`` if an
  ## error occurs. This is supposed to be used for quick scripting.
  var x = readFile(infile)
  if not isNil(x):
    var f: TFile
    if open(f, outfile, fmWrite):
      write(f, x.parallelReplace(subs))
      close(f)
    else:
      quit("cannot open for writing: " & outfile)
  else:
    quit("cannot open for reading: " & infile)
  
iterator split*(s: string, sep: TRegEx): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by the regular expression `sep`.
  ## Examples:
  ##
  ## .. code-block:: nimrod
  ##   for word in split("00232this02939is39an22example111", re"\d+"):
  ##     writeln(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  var
    first = 0
    last = 0
  while last < len(s):
    var x = matchLen(s, sep, last)
    if x > 0: inc(last, x)
    first = last
    while last < len(s):
      inc(last)
      x = matchLen(s, sep, last)
      if x > 0: break
    if first < last:
      yield copy(s, first, last-1)

proc split*(s: string, sep: TRegEx): seq[string] =
  ## Splits the string `s` into substrings.
  accumulateResult(split(s, sep))
  
const ## common regular expressions
  reIdentifier* = r"\b[a-zA-Z_]+[a-zA-Z_0-9]*\b"  ## describes an identifier
  reNatural* = r"\b\d+\b" ## describes a natural number
  reInteger* = r"\b[-+]?\d+\b" ## describes an integer
  reHex* = r"\b0[xX][0-9a-fA-F]+\b" ## describes a hexadecimal number
  reBinary* = r"\b0[bB][01]+\b" ## describes a binary number (example: 0b11101)
  reOctal* = r"\b0[oO][0-7]+\b" ## describes an octal number (example: 0o777)
  reFloat* = r"\b[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\b"
    ## describes a floating point number
  reEmail* = r"\b[a-zA-Z0-9!#$%&'*+/=?^_`{|}~\-]+(?:\. &" &
             r"[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)" &
             r"*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+" &
             r"(?:[a-zA-Z]{2}|com|org|" &
             r"net|gov|mil|biz|info|mobi|name|aero|jobs|museum)\b"
    ## describes a common email address
  reURL* = r"\b(http(s)?|ftp|gopher|telnet|file|notes|ms\-help):" &
           r"((//)|(\\\\))+[\w\d:#@%/;$()~_?\+\-\=\\\.\&]*\b"
    ## describes an URL

when isMainModule:
  echo matchLen("key", re"[a-zA-Z_][a-zA-Z_0-9]*")

  var pattern = re"[a-zA-Z_][a-zA-Z_0-9]*\s*=\s*[a-zA-Z_][a-zA-Z_0-9]*"
  echo matchLen("key1=  cal9", pattern, 2)

  echo find("_____abc_______", re("abc"), 3)
  #echo "var1=key; var2=key2".replace(peg"{\ident}'='{\ident}", "$1<-$2$2")
  #echo "var1=key; var2=key2".endsWith(peg"{\ident}'='{\ident}")

  if "abc" =~ re"(a)bc xyz|([a-z]+)":
    echo matches[0]
  else:
    echo "BUG"

#  for word in split("00232this02939is39an22example111", peg"\d+"):
#    writeln(stdout, word)
