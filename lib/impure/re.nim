#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#        (c) Copyright 2015 Oleh Prypin
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Regular expression support for Nim.
##
## **Note:** The 're' proc defaults to the **extended regular expression
## syntax** which lets you use whitespace freely to make your regexes readable.
## However, this means to match whitespace ``\s`` or something similar has
## to be used.
##
## This module is implemented by providing a wrapper around the
## `PRCE (Perl-Compatible Regular Expressions) <http://www.pcre.org>`_
## C library. This means that your application will depend on the PRCE
## library's licence when using this module, which should not be a problem
## though.
## PRCE's licence follows:
##
## .. include:: ../doc/regexprs.txt
##


import strutils
import nre, options

type Regex = nre.Regex

const
  MaxSubpatterns* {.deprecated.} = 1000
    ## This is obsolete. There is no limit on the number of subpatterns.

type
  RegexFlag* = enum     ## options for regular expressions
    reIgnoreCase = 0,    ## do caseless matching
    reMultiLine = 1,     ## ``^`` and ``$`` match newlines within data
    reDotAll = 2,        ## ``.`` matches anything including NL
    reExtended = 3,      ## ignore whitespace and ``#`` comments
    reStudy = 4          ## study the expression (may be omitted if the
                         ## expression will be used only once)

  RegexError* = object of ValueError
    ## is raised if the pattern is no valid regular expression.


proc re*(s: string, flags = {reExtended, reStudy}): Regex =
  ## Constructor of regular expressions. Note that Nim's
  ## extended raw string literals support this syntax ``re"[abc]"`` as
  ## a short form for ``re(r"[abc]")``.
  var options = ""
  if reStudy notin flags:
    options.add "(*NO_STUDY)"
  for t in [
    (reIgnoreCase, "(?i)"),
    (reMultiLine, "(?m)"),
    (reDotAll, "(?s)"),
    (reExtended, "(?x)")
  ]:
    if t[0] in flags:
      options.add t[1]
  try:
    return nre.re(options & s)
  except nre.SyntaxError:
    let e = nre.SyntaxError(getCurrentException())
    raise newException(RegexError, e.msg & "\n" & e.pattern & "\n" &
                                   repeat(' ', e.pos) & "^\n")
  except nre.StudyError:
    let e = nre.StudyError(getCurrentException())
    raise newException(RegexError, "Study error: " & e.msg)


template execute(f: expr, notFound: stmt): stmt {.immediate, dirty.} =
  let mm = f(s, pattern, start)
  var m: RegexMatch
  if mm.isSome:
    m = mm.unsafeGet()
  else:
    notFound

template stringCaptures(): stmt {.immediate, dirty.} =
  for i in 0 .. <pattern.captureCount:
    matches[i] = m.captures[i]

template boundCaptures(): stmt {.immediate, dirty.} =
  for i in 0 .. <pattern.captureCount:
    let b = m.captureBounds[i]
    matches[i] =
      if b.isSome: (b.unsafeGet().a, <b.unsafeGet().b)
      else: (-1, 0)

template returnBounds(): stmt {.immediate, dirty.} =
  return (m.matchBounds.a, <m.matchBounds.b)

template returnLength(): stmt {.immediate, dirty.} =
  return m.matchBounds.b - m.matchBounds.a

proc findBounds*(s: string, pattern: Regex, matches: var openArray[string],
                 start = 0): tuple[first, last: int] =
  ## returns the starting position and end position of `pattern` in `s`
  ## and the captured
  ## substrings in the array `matches`. If it does not match, nothing
  ## is written into `matches` and ``(-1,0)`` is returned.
  execute nre.find:
    return (-1, 0)
  stringCaptures()
  returnBounds()

proc findBounds*(s: string, pattern: Regex,
                 matches: var openArray[tuple[first, last: int]],
                 start = 0): tuple[first, last: int] =
  ## returns the starting position and end position of ``pattern`` in ``s``
  ## and the captured substrings in the array `matches`.
  ## If it does not match, nothing is written into `matches` and
  ## ``(-1,0)`` is returned.
  execute nre.find:
    return (-1, 0)
  boundCaptures()
  returnBounds()

proc findBounds*(s: string, pattern: Regex,
                 start = 0): tuple[first, last: int] =
  ## returns the starting position of `pattern` in `s`. If it does not
  ## match, ``(-1,0)`` is returned.
  execute nre.find:
    return (-1, 0)
  returnBounds()

proc matchLen*(s: string, pattern: Regex, matches: var openArray[string],
               start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.
  execute nre.match:
    return -1
  stringCaptures()
  returnLength()

proc matchLen*(s: string, pattern: Regex, start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.
  execute nre.match:
    return -1
  returnLength()

proc match*(s: string, pattern: Regex, start = 0): bool =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern``.
  execute nre.match:
    return false
  return true

proc match*(s: string, pattern: Regex, matches: var openArray[string],
           start = 0): bool =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  execute nre.match:
    return false
  stringCaptures()
  return true

proc find*(s: string, pattern: Regex, matches: var openArray[string],
           start = 0): int =
  ## returns the starting position of ``pattern`` in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and -1 is returned.
  execute nre.find:
    return -1
  stringCaptures()
  return m.matchBounds.a

proc find*(s: string, pattern: Regex, start = 0): int =
  ## returns the starting position of ``pattern`` in ``s``. If it does not
  ## match, -1 is returned.
  execute nre.find:
    return -1
  return m.matchBounds.a

iterator findAll*(s: string, pattern: Regex, start = 0): string =
  ## Yields all matching *substrings* of `s` that match `pattern`.
  ##
  ## Note that since this is an iterator you should not modify the string you
  ## are iterating over: bad things could happen.
  for m in nre.findIter(s, pattern, start):
    yield $m

proc findAll*(s: string, pattern: Regex, start = 0): seq[string] =
  ## returns all matching *substrings* of `s` that match `pattern`.
  ## If it does not match, @[] is returned.
  accumulateResult findAll(s, pattern, start)

when not defined(nimhygiene):
  {.pragma: inject.}

template `=~`*(s: string, pattern: Regex, start = 0): expr =
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
  let mm = nre.match(s, pattern, start)
  var matches {.inject.}: seq[string]
  if mm.isSome:
    matches = mm.unsafeGet().captures.toSeq()
  mm.isSome

# ------------------------- more string handling ------------------------------

proc contains*(s: string, pattern: Regex, start = 0): bool =
  ## same as ``find(s, pattern, start) >= 0``
  return find(s, pattern, start) >= 0

proc contains*(s: string, pattern: Regex, matches: var openArray[string],
              start = 0): bool =
  ## same as ``find(s, pattern, matches, start) >= 0``
  return find(s, pattern, matches, start) >= 0

proc startsWith*(s: string, prefix: Regex): bool =
  ## returns true if `s` starts with the pattern `prefix`
  result = matchLen(s, prefix) >= 0

proc endsWith*(s: string, suffix: Regex): bool =
  ## returns true if `s` ends with the pattern `prefix`
  for i in 0 .. s.high:
    if matchLen(s, suffix, i) == s.len - i:
      return true

proc replace*(s: string, sub: Regex, by = ""): string =
  ## Replaces `sub` in `s` by the string `by`. Captures cannot be
  ## accessed in `by`. Examples:
  ##
  ## .. code-block:: nim
  ##   "var1=key; var2=key2".replace(re"(\w+)=(\w+)")
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##
  ##   "; "
  return nre.replace(s, sub, by.replace("$", "$$"))

proc replacef*(s: string, sub: Regex, by: string): string =
  ## Replaces `sub` in `s` by the string `by`. Captures can be accessed in `by`
  ## with the notation ``$i`` and ``$#`` (see strutils.`%`). Examples:
  ##
  ## .. code-block:: nim
  ##   "var1=key; var2=key2".replacef(re"(\w+)=(\w+)", "$1<-$2$2")
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##
  ## "var1<-keykey; val2<-key2key2"
  return nre.replace(s, sub, by)

proc parallelReplace*(s: string, subs: openArray[
                      tuple[pattern: Regex, repl: string]]): string =
  ## Returns a modified copy of `s` with the substitutions in `subs`
  ## applied in parallel.
  result = ""
  var i = 0
  while i < s.len:
    block searchSubs:
      for sub in subs:
        let pattern = sub.pattern
        let start = i
        execute nre.match:
          continue
        result.addf sub.repl, m.captures.toSeq()
        i += m.matchBounds.b - m.matchBounds.a
        break searchSubs
      result.add s[i]
      inc i
  # copy the rest:
  result.add s.substr(i)

proc transformFile*(infile, outfile: string,
                    subs: openArray[tuple[pattern: Regex, repl: string]]) =
  ## reads in the file `infile`, performs a parallel replacement (calls
  ## `parallelReplace`) and writes back to `outfile`. Raises ``EIO`` if an
  ## error occurs. This is supposed to be used for quick scripting.
  var x = readFile(infile).string
  writeFile(outfile, x.parallelReplace(subs))

iterator split*(s: string, sep: Regex): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by the regular expression `sep`.
  ## Examples:
  ##
  ## .. code-block:: nim
  ##   for word in split("00232this02939is39an22example111", re"\d+"):
  ##     writeln(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  for m in nre.split(s, sep):
    yield m

proc split*(s: string, sep: Regex): seq[string] =
  ## Splits the string `s` into substrings.
  return nre.split(s, sep)

proc escapeRe*(s: string): string =
  ## escapes `s` so that it is matched verbatim when used as a regular
  ## expression.
  return nre.escapeRe(s)

const ## common regular expressions
  reIdentifier* = r"\b[a-zA-Z_]+[a-zA-Z_0-9]*\b"  ## describes an identifier
  reNatural* = r"\b\d+\b" ## describes a natural number
  reInteger* = r"\b[-+]?\d+\b" ## describes an integer
  reHex* = r"\b0[xX][0-9a-fA-F]+\b" ## describes a hexadecimal number
  reBinary* = r"\b0[bB][01]+\b" ## describes a binary number (example: 0b11101)
  reOctal* = r"\b0[oO][0-7]+\b" ## describes an octal number (example: 0o777)
  reFloat* = r"\b[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\b"
    ## describes a floating point number
  reEmail* {.deprecated.} =
    r"\b[a-zA-Z0-9!#$%&'*+/=?^_`{|}~\-]+(?:\. &" &
    r"[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)" &
    r"*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+" &
    r"(?:[a-zA-Z]{2}|com|org|" &
    r"net|gov|mil|biz|info|mobi|name|aero|jobs|museum)\b"
    ## describes a common email address
  reURL* {.deprecated.} =
    r"\b(http(s)?|ftp|gopher|telnet|file|notes|ms\-help):" &
    r"((//)|(\\\\))+[\w\d:#@%/;$()~_?\+\-\=\\\.\&]*\b"
    ## describes an URL

when isMainModule:
  assert match("(a b c)", re"\( .* \)")
  assert match("WHiLe", re("while", {reIgnoreCase}))

  assert "0158787".match(re"\d+")
  assert "ABC 0232".match(re"\w+\s+\d+")
  assert "ABC".match(re"\d+ | \w+")

  assert matchLen("key", re(reIdentifier)) == 3

  var pattern = re"[a-z0-9]+\s*=\s*[a-z0-9]+"
  assert matchLen("key1=  cal9", pattern) == 11

  assert find("_____abc_______", re"abc") == 5

  var matches: array[0..5, string]
  if match("abcdefg", re"c(d)ef(g)", matches, 2):
    assert matches[0] == "d"
    assert matches[1] == "g"
  else:
    assert false

  if "abc" =~ re"(a)bcxyz|(\w+)":
    assert matches[1] == "abc"
  else: assert false

  if "abc" =~ re"(cba)?.*":
    assert matches[0] == nil
  else: assert false

  if "abc" =~ re"().*":
    assert matches[0] == ""
  else: assert false

  assert "var1=key; var2=key2".endsWith(re"\w+=\w+")
  assert("var1=key; var2=key2".replacef(re"(\w+)=(\w+)", "$1<-$2$2") ==
         "var1<-keykey; var2<-key2key2")
  assert("var1=key; var2=key2".replace(re"(\w+)=(\w+)", "$1<-$2$2") ==
         "$1<-$2$2; $1<-$2$2")

  var accum: seq[string] = split("00232this02939is39an22example111", re"\d+")
  assert(accum == @["", "this", "is", "an", "example", ""])

  for x in findAll("abcdef", re"^{.}", 3):
    assert x == "d"
  accum = @[]
  for x in findAll("abcdef", re".", 3):
    accum.add(x)
  assert(accum == @["d", "e", "f"])

  assert("XYZ".find(re"^\d*") == 0)
  assert("XYZ".match(re"^\d*") == true)

  block:
    var matches: array[0..15, string]
    if match("abcdefghijklmnop",
             re"(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)", matches):
      for i in 0 .. matches.high:
        assert matches[i] == $chr(i + 'a'.ord)
    else:
      assert false
