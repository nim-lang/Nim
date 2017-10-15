#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Regular expression support for Nim. This module still has some
## obscure bugs and limitations,
## consider using the ``nre`` or ``pegs`` modules instead.
## We had to de-deprecate this module since too much code relies on it
## and many people prefer its API over ``nre``'s.
##
## This module is implemented by providing a wrapper around the
## `PRCE (Perl-Compatible Regular Expressions) <http://www.pcre.org>`_
## C library. This means that your application will depend on the PRCE
## library's licence when using this module, which should not be a problem
## though.
## PRCE's licence follows:
##
## .. include:: ../../doc/regexprs.txt
##

import
  pcre, strutils, rtarrays

const
  MaxSubpatterns* = 20
    ## defines the maximum number of subpatterns that can be captured.
    ## This limit still exists for ``replacef`` and ``parallelReplace``.

type
  RegexFlag* = enum     ## options for regular expressions
    reIgnoreCase = 0,    ## do caseless matching
    reMultiLine = 1,     ## ``^`` and ``$`` match newlines within data
    reDotAll = 2,        ## ``.`` matches anything including NL
    reExtended = 3,      ## ignore whitespace and ``#`` comments
    reStudy = 4          ## study the expression (may be omitted if the
                         ## expression will be used only once)

  RegexDesc = object
    h: ptr Pcre
    e: ptr ExtraData

  Regex* = ref RegexDesc ## a compiled regular expression

  RegexError* = object of ValueError
    ## is raised if the pattern is no valid regular expression.

{.deprecated: [TRegexFlag: RegexFlag, TRegexDesc: RegexDesc, TRegex: Regex,
    EInvalidRegEx: RegexError].}

proc raiseInvalidRegex(msg: string) {.noinline, noreturn.} =
  var e: ref RegexError
  new(e)
  e.msg = msg
  raise e

proc rawCompile(pattern: string, flags: cint): ptr Pcre =
  var
    msg: cstring = ""
    offset: cint = 0
  result = pcre.compile(pattern, flags, addr(msg), addr(offset), nil)
  if result == nil:
    raiseInvalidRegex($msg & "\n" & pattern & "\n" & spaces(offset) & "^\n")

proc finalizeRegEx(x: Regex) =
  # XXX This is a hack, but PCRE does not export its "free" function properly.
  # Sigh. The hack relies on PCRE's implementation (see ``pcre_get.c``).
  # Fortunately the implementation is unlikely to change.
  pcre.free_substring(cast[cstring](x.h))
  if not isNil(x.e):
    pcre.free_substring(cast[cstring](x.e))

proc re*(s: string, flags = {reStudy}): Regex =
  ## Constructor of regular expressions.
  ##
  ## Note that Nim's
  ## extended raw string literals support the syntax ``re"[abc]"`` as
  ## a short form for ``re(r"[abc]")``.
  new(result, finalizeRegEx)
  result.h = rawCompile(s, cast[cint](flags - {reStudy}))
  if reStudy in flags:
    var msg: cstring = ""
    var options: cint = 0
    var hasJit: cint = 0
    if pcre.config(pcre.CONFIG_JIT, addr hasJit) == 0:
      if hasJit == 1'i32:
        options = pcre.STUDY_JIT_COMPILE
    result.e = pcre.study(result.h, options, addr msg)
    if not isNil(msg): raiseInvalidRegex($msg)

proc bufSubstr(b: cstring, sPos, ePos: int): string {.inline.} =
  ## Return a Nim string built from a slice of a cstring buffer.
  ## Don't assume cstring is '\0' terminated
  let sz = ePos - sPos
  result = newString(sz+1)
  copyMem(addr(result[0]), unsafeaddr(b[sPos]), sz)
  result.setLen(sz)

proc matchOrFind(buf: cstring, pattern: Regex, matches: var openArray[string],
                 start, bufSize, flags: cint): cint =
  var
    rtarray = initRtArray[cint]((matches.len+1)*3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize, start, flags,
      cast[ptr cint](rawMatches), (matches.len+1).cint*3)
  if res < 0'i32: return res
  for i in 1..int(res)-1:
    var a = rawMatches[i * 2]
    var b = rawMatches[i * 2 + 1]
    if a >= 0'i32:
      matches[i-1] = bufSubstr(buf, int(a), int(b))
    else: matches[i-1] = nil
  return rawMatches[1] - rawMatches[0]

proc findBounds*(buf: cstring, pattern: Regex, matches: var openArray[string],
                 start = 0, bufSize: int): tuple[first, last: int] =
  ## returns the starting position and end position of ``pattern`` in ``buf``
  ## (where ``buf`` has length ``bufSize`` and is not necessarily ``'\0'`` terminated),
  ## and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and ``(-1,0)`` is returned.
  var
    rtarray = initRtArray[cint]((matches.len+1)*3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, 0'i32,
      cast[ptr cint](rawMatches), (matches.len+1).cint*3)
  if res < 0'i32: return (-1, 0)
  for i in 1..int(res)-1:
    var a = rawMatches[i * 2]
    var b = rawMatches[i * 2 + 1]
    if a >= 0'i32: matches[i-1] = bufSubstr(buf, int(a), int(b))
    else: matches[i-1] = nil
  return (rawMatches[0].int, rawMatches[1].int - 1)

proc findBounds*(s: string, pattern: Regex, matches: var openArray[string],
                 start = 0): tuple[first, last: int] {.inline.} =
  ## returns the starting position and end position of ``pattern`` in ``s``
  ## and the captured substrings in the array ``matches``.
  ## If it does not match, nothing
  ## is written into ``matches`` and ``(-1,0)`` is returned.
  result = findBounds(cstring(s), pattern, matches, start, s.len)

proc findBounds*(buf: cstring, pattern: Regex,
                 matches: var openArray[tuple[first, last: int]],
                 start = 0, bufSize = 0): tuple[first, last: int] =
  ## returns the starting position and end position of ``pattern`` in ``buf``
  ## (where ``buf`` has length ``bufSize`` and is not necessarily ``'\0'`` terminated),
  ## and the captured substrings in the array ``matches``.
  ## If it does not match, nothing is written into ``matches`` and
  ## ``(-1,0)`` is returned.
  var
    rtarray = initRtArray[cint]((matches.len+1)*3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, 0'i32,
      cast[ptr cint](rawMatches), (matches.len+1).cint*3)
  if res < 0'i32: return (-1, 0)
  for i in 1..int(res)-1:
    var a = rawMatches[i * 2]
    var b = rawMatches[i * 2 + 1]
    if a >= 0'i32: matches[i-1] = (int(a), int(b)-1)
    else: matches[i-1] = (-1,0)
  return (rawMatches[0].int, rawMatches[1].int - 1)

proc findBounds*(s: string, pattern: Regex,
                 matches: var openArray[tuple[first, last: int]],
                 start = 0): tuple[first, last: int] {.inline.} =
  ## returns the starting position and end position of ``pattern`` in ``s``
  ## and the captured substrings in the array ``matches``.
  ## If it does not match, nothing is written into ``matches`` and
  ## ``(-1,0)`` is returned.
  result = findBounds(cstring(s), pattern, matches, start, s.len)

proc findBounds*(buf: cstring, pattern: Regex,
                 start = 0, bufSize: int): tuple[first, last: int] =
  ## returns the ``first`` and ``last`` position of ``pattern`` in ``buf``,
  ## where ``buf`` has length ``bufSize`` (not necessarily ``'\0'`` terminated).
  ## If it does not match, ``(-1,0)`` is returned.
  var
    rtarray = initRtArray[cint](3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, 0'i32,
      cast[ptr cint](rawMatches), 3)
  if res < 0'i32: return (int(res), 0)
  return (int(rawMatches[0]), int(rawMatches[1]-1))

proc findBounds*(s: string, pattern: Regex,
                 start = 0): tuple[first, last: int] {.inline.} =
  ## returns the ``first`` and ``last`` position of ``pattern`` in ``s``.
  ## If it does not match, ``(-1,0)`` is returned.
  ##
  ## Note: there is a speed improvement if the matches do not need to be captured.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   assert findBounds("01234abc89", re"abc") == (5,7)
  result = findBounds(cstring(s), pattern, start, s.len)

proc matchOrFind(buf: cstring, pattern: Regex, start, bufSize: int, flags: cint): cint =
  var
    rtarray = initRtArray[cint](3)
    rawMatches = rtarray.getRawData
  result = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, flags,
                    cast[ptr cint](rawMatches), 3)
  if result >= 0'i32:
    result = rawMatches[1] - rawMatches[0]

proc matchLen*(s: string, pattern: Regex, matches: var openArray[string],
              start = 0): int {.inline.} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, ``-1`` is returned. Note that a match length
  ## of zero can happen.
  result = matchOrFind(cstring(s), pattern, matches, start.cint, s.len.cint, pcre.ANCHORED)

proc matchLen*(buf: cstring, pattern: Regex, matches: var openArray[string],
              start = 0, bufSize: int): int {.inline.} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, ``-1`` is returned. Note that a match length
  ## of zero can happen.
  return matchOrFind(buf, pattern, matches, start.cint, bufSize.cint, pcre.ANCHORED)

proc matchLen*(s: string, pattern: Regex, start = 0): int {.inline.} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, ``-1`` is returned. Note that a match length
  ## of zero can happen.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   echo matchLen("abcdefg", re"cde", 2)  # =>  3
  ##   echo matchLen("abcdefg", re"abcde")   # =>  5
  ##   echo matchLen("abcdefg", re"cde")     # => -1
  result = matchOrFind(cstring(s), pattern, start.cint, s.len.cint, pcre.ANCHORED)

proc matchLen*(buf: cstring, pattern: Regex, start = 0, bufSize: int): int {.inline.} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, ``-1`` is returned. Note that a match length
  ## of zero can happen.
  result = matchOrFind(buf, pattern, start.cint, bufSize, pcre.ANCHORED)

proc match*(s: string, pattern: Regex, start = 0): bool {.inline.} =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern``.
  result = matchLen(cstring(s), pattern, start, s.len) != -1

proc match*(s: string, pattern: Regex, matches: var openArray[string],
           start = 0): bool {.inline.} =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var matches: array[2, string]
  ##   if match("abcdefg", re"c(d)ef(g)", matches, 2):
  ##     for s in matches:
  ##       echo s       # => d g
  result = matchLen(cstring(s), pattern, matches, start, s.len) != -1

proc match*(buf: cstring, pattern: Regex, matches: var openArray[string],
           start = 0, bufSize: int): bool {.inline.} =
  ## returns ``true`` if ``buf[start..<bufSize]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  ## ``buf`` has length ``bufSize`` (not necessarily ``'\0'`` terminated).
  result = matchLen(buf, pattern, matches, start, bufSize) != -1

proc find*(buf: cstring, pattern: Regex, matches: var openArray[string],
           start = 0, bufSize = 0): int =
  ## returns the starting position of ``pattern`` in ``buf`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and ``-1`` is returned.
  ## ``buf`` has length ``bufSize`` (not necessarily ``'\0'`` terminated).
  var
    rtarray = initRtArray[cint]((matches.len+1)*3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, 0'i32,
      cast[ptr cint](rawMatches), (matches.len+1).cint*3)
  if res < 0'i32: return res
  for i in 1..int(res)-1:
    var a = rawMatches[i * 2]
    var b = rawMatches[i * 2 + 1]
    if a >= 0'i32: matches[i-1] = bufSubstr(buf, int(a), int(b))
    else: matches[i-1] = nil
  return rawMatches[0]

proc find*(s: string, pattern: Regex, matches: var openArray[string],
           start = 0): int {.inline.} =
  ## returns the starting position of ``pattern`` in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and ``-1`` is returned.
  result = find(cstring(s), pattern, matches, start, s.len)

proc find*(buf: cstring, pattern: Regex, start = 0, bufSize: int): int =
  ## returns the starting position of ``pattern`` in ``buf``,
  ## where ``buf`` has length ``bufSize`` (not necessarily ``'\0'`` terminated).
  ## If it does not match, ``-1`` is returned.
  var
    rtarray = initRtArray[cint](3)
    rawMatches = rtarray.getRawData
    res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, start.cint, 0'i32,
      cast[ptr cint](rawMatches), 3)
  if res < 0'i32: return res
  return rawMatches[0]

proc find*(s: string, pattern: Regex, start = 0): int {.inline.} =
  ## returns the starting position of ``pattern`` in ``s``. If it does not
  ## match, ``-1`` is returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  echo find("abcdefg", re"cde")  # => 2
  ##  echo find("abcdefg", re"abc")  # => 0
  ##  echo find("abcdefg", re"zz")  # => -1
  result = find(cstring(s), pattern, start, s.len)

iterator findAll*(s: string, pattern: Regex, start = 0): string =
  ## Yields all matching *substrings* of `s` that match `pattern`.
  ##
  ## Note that since this is an iterator you should not modify the string you
  ## are iterating over: bad things could happen.
  var
    i = int32(start)
    rtarray = initRtArray[cint](3)
    rawMatches = rtarray.getRawData
  while true:
    let res = pcre.exec(pattern.h, pattern.e, s, len(s).cint, i, 0'i32,
      cast[ptr cint](rawMatches), 3)
    if res < 0'i32: break
    let a = rawMatches[0]
    let b = rawMatches[1]
    if a == b and a == i: break
    yield substr(s, int(a), int(b)-1)
    i = b

iterator findAll*(buf: cstring, pattern: Regex, start = 0, bufSize: int): string =
  ## Yields all matching `substrings` of ``s`` that match ``pattern``.
  ##
  ## Note that since this is an iterator you should not modify the string you
  ## are iterating over: bad things could happen.
  var
    i = int32(start)
    rtarray = initRtArray[cint](3)
    rawMatches = rtarray.getRawData
  while true:
    let res = pcre.exec(pattern.h, pattern.e, buf, bufSize.cint, i, 0'i32,
      cast[ptr cint](rawMatches), 3)
    if res < 0'i32: break
    let a = rawMatches[0]
    let b = rawMatches[1]
    if a == b and a == i: break
    var str = newString(b-a)
    copyMem(str[0].addr, unsafeAddr(buf[a]), b-a)
    yield str
    i = b

proc findAll*(s: string, pattern: Regex, start = 0): seq[string] {.inline.} =
  ## returns all matching `substrings` of ``s`` that match ``pattern``.
  ## If it does not match, @[] is returned.
  accumulateResult(findAll(s, pattern, start))

when not defined(nimhygiene):
  {.pragma: inject.}

template `=~` *(s: string, pattern: Regex): untyped =
  ## This calls ``match`` with an implicit declared ``matches`` array that
  ## can be used in the scope of the ``=~`` call:
  ##
  ## .. code-block:: nim
  ##
  ##   if line =~ re"\s*(\w+)\s*\=\s*(\w+)":
  ##     # matches a key=value pair:
  ##     echo("Key: ", matches[0])
  ##     echo("Value: ", matches[1])
  ##   elif line =~ re"\s*(\#.*)":
  ##     # matches a comment
  ##     # note that the implicit ``matches`` array is different from the
  ##     # ``matches`` array of the first branch
  ##     echo("comment: ", matches[0])
  ##   else:
  ##     echo("syntax error")
  ##
  bind MaxSubpatterns
  when not declaredInScope(matches):
    var matches {.inject.}: array[MaxSubpatterns, string]
  match(s, pattern, matches)

# ------------------------- more string handling ------------------------------

proc contains*(s: string, pattern: Regex, start = 0): bool {.inline.} =
  ## same as ``find(s, pattern, start) >= 0``
  return find(s, pattern, start) >= 0

proc contains*(s: string, pattern: Regex, matches: var openArray[string],
              start = 0): bool {.inline.} =
  ## same as ``find(s, pattern, matches, start) >= 0``
  return find(s, pattern, matches, start) >= 0

proc startsWith*(s: string, prefix: Regex): bool {.inline.} =
  ## returns true if `s` starts with the pattern `prefix`
  result = matchLen(s, prefix) >= 0

proc endsWith*(s: string, suffix: Regex): bool {.inline.} =
  ## returns true if `s` ends with the pattern `prefix`
  for i in 0 .. s.len-1:
    if matchLen(s, suffix, i) == s.len - i: return true

proc replace*(s: string, sub: Regex, by = ""): string =
  ## Replaces ``sub`` in ``s`` by the string ``by``. Captures cannot be
  ## accessed in ``by``.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   "var1=key; var2=key2".replace(re"(\w+)=(\w+)")
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##
  ##   "; "
  result = ""
  var prev = 0
  while true:
    var match = findBounds(s, sub, prev)
    if match.first < 0: break
    add(result, substr(s, prev, match.first-1))
    add(result, by)
    prev = match.last + 1
  add(result, substr(s, prev))

proc replacef*(s: string, sub: Regex, by: string): string =
  ## Replaces ``sub`` in ``s`` by the string ``by``. Captures can be accessed in ``by``
  ## with the notation ``$i`` and ``$#`` (see strutils.\`%\`).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   "var1=key; var2=key2".replacef(re"(\w+)=(\w+)", "$1<-$2$2")
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##
  ## "var1<-keykey; val2<-key2key2"
  result = ""
  var caps: array[MaxSubpatterns, string]
  var prev = 0
  while true:
    var match = findBounds(s, sub, caps, prev)
    if match.first < 0: break
    assert result != nil
    assert s != nil
    add(result, substr(s, prev, match.first-1))
    addf(result, by, caps)
    prev = match.last + 1
  add(result, substr(s, prev))

proc parallelReplace*(s: string, subs: openArray[
                      tuple[pattern: Regex, repl: string]]): string =
  ## Returns a modified copy of ``s`` with the substitutions in ``subs``
  ## applied in parallel.
  result = ""
  var i = 0
  var caps: array[MaxSubpatterns, string]
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
  add(result, substr(s, i))

proc transformFile*(infile, outfile: string,
                    subs: openArray[tuple[pattern: Regex, repl: string]]) =
  ## reads in the file ``infile``, performs a parallel replacement (calls
  ## ``parallelReplace``) and writes back to ``outfile``. Raises ``IOError`` if an
  ## error occurs. This is supposed to be used for quick scripting.
  var x = readFile(infile).string
  writeFile(outfile, x.parallelReplace(subs))

iterator split*(s: string, sep: Regex): string =
  ## Splits the string ``s`` into substrings.
  ##
  ## Substrings are separated by the regular expression ``sep``
  ## (and the portion matched by ``sep`` is not returned).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   for word in split("00232this02939is39an22example111", re"\d+"):
  ##     writeLine(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   ""
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##   ""
  ##
  var
    first = -1
    last = -1
  while last < len(s):
    var x = matchLen(s, sep, last)
    if x > 0: inc(last, x)
    first = last
    if x == 0: inc(last)
    while last < len(s):
      x = matchLen(s, sep, last)
      if x >= 0: break
      inc(last)
    if first <= last:
      yield substr(s, first, last-1)

proc split*(s: string, sep: Regex): seq[string] {.inline.} =
  ## Splits the string ``s`` into a seq of substrings.
  ##
  ## The portion matched by ``sep`` is not returned.
  accumulateResult(split(s, sep))

proc escapeRe*(s: string): string =
  ## escapes ``s`` so that it is matched verbatim when used as a regular
  ## expression.
  result = ""
  for c in items(s):
    case c
    of 'a'..'z', 'A'..'Z', '0'..'9', '_':
      result.add(c)
    else:
      result.add("\\x")
      result.add(toHex(ord(c), 2))

const ## common regular expressions
  reIdentifier* {.deprecated.} = r"\b[a-zA-Z_]+[a-zA-Z_0-9]*\b"
    ## describes an identifier
  reNatural* {.deprecated.} = r"\b\d+\b"
    ## describes a natural number
  reInteger* {.deprecated.} = r"\b[-+]?\d+\b"
    ## describes an integer
  reHex* {.deprecated.} = r"\b0[xX][0-9a-fA-F]+\b"
    ## describes a hexadecimal number
  reBinary* {.deprecated.} = r"\b0[bB][01]+\b"
    ## describes a binary number (example: 0b11101)
  reOctal* {.deprecated.} = r"\b0[oO][0-7]+\b"
    ## describes an octal number (example: 0o777)
  reFloat* {.deprecated.} = r"\b[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\b"
    ## describes a floating point number
  reEmail* {.deprecated.} = r"\b[a-zA-Z0-9!#$%&'*+/=?^_`{|}~\-]+(?:\. &" &
                            r"[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*@" &
                            r"(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+" &
                            r"(?:[a-zA-Z]{2}|com|org|net|gov|mil|biz|" &
                            r"info|mobi|name|aero|jobs|museum)\b"
    ## describes a common email address
  reURL* {.deprecated.} = r"\b(http(s)?|ftp|gopher|telnet|file|notes|ms-help)" &
                          r":((//)|(\\\\))+[\w\d:#@%/;$()~_?\+\-\=\\\.\&]*\b"
    ## describes an URL

when isMainModule:
  doAssert match("(a b c)", re"\( .* \)")
  doAssert match("WHiLe", re("while", {reIgnoreCase}))

  doAssert "0158787".match(re"\d+")
  doAssert "ABC 0232".match(re"\w+\s+\d+")
  doAssert "ABC".match(re"\d+ | \w+")

  {.push warnings:off.}
  doAssert matchLen("key", re(reIdentifier)) == 3
  {.pop.}

  var pattern = re"[a-z0-9]+\s*=\s*[a-z0-9]+"
  doAssert matchLen("key1=  cal9", pattern) == 11

  doAssert find("_____abc_______", re"abc") == 5
  doAssert findBounds("_____abc_______", re"abc") == (5,7)

  var matches: array[6, string]
  if match("abcdefg", re"c(d)ef(g)", matches, 2):
    doAssert matches[0] == "d"
    doAssert matches[1] == "g"
  else:
    doAssert false

  if "abc" =~ re"(a)bcxyz|(\w+)":
    doAssert matches[1] == "abc"
  else:
    doAssert false

  if "abc" =~ re"(cba)?.*":
    doAssert matches[0] == nil
  else: doAssert false

  if "abc" =~ re"().*":
    doAssert matches[0] == ""
  else: doAssert false

  doAssert "var1=key; var2=key2".endsWith(re"\w+=\w+")
  doAssert("var1=key; var2=key2".replacef(re"(\w+)=(\w+)", "$1<-$2$2") ==
         "var1<-keykey; var2<-key2key2")
  doAssert("var1=key; var2=key2".replace(re"(\w+)=(\w+)", "$1<-$2$2") ==
         "$1<-$2$2; $1<-$2$2")

  var accum: seq[string] = @[]
  for word in split("00232this02939is39an22example111", re"\d+"):
    accum.add(word)
  doAssert(accum == @["", "this", "is", "an", "example", ""])

  accum = @[]
  for word in split("AAA :   : BBB", re"\s*:\s*"):
    accum.add(word)
  doAssert(accum == @["AAA", "", "BBB"])

  for x in findAll("abcdef", re"^{.}", 3):
    doAssert x == "d"
  accum = @[]
  for x in findAll("abcdef", re".", 3):
    accum.add(x)
  doAssert(accum == @["d", "e", "f"])

  doAssert("XYZ".find(re"^\d*") == 0)
  doAssert("XYZ".match(re"^\d*") == true)

  block:
    var matches: array[16, string]
    if match("abcdefghijklmnop", re"(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)", matches):
      for i in 0..matches.high:
        doAssert matches[i] == $chr(i + 'a'.ord)
    else:
      doAssert false

  block:   # Buffer based RE
    var cs: cstring = "_____abc_______"
    doAssert(cs.find(re"abc", bufSize=15) == 5)
    doAssert(cs.matchLen(re"_*abc", bufSize=15) == 8)
    doAssert(cs.matchLen(re"abc", start=5, bufSize=15) == 3)
    doAssert(cs.matchLen(re"abc", start=5, bufSize=7) == -1)
    doAssert(cs.matchLen(re"abc_*", start=5, bufSize=10) == 5)
    var accum: seq[string] = @[]
    for x in cs.findAll(re"[a-z]", start=3, bufSize=15):
      accum.add($x)
    doAssert(accum == @["a","b","c"])

