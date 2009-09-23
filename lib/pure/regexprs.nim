#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Regular expression support for Nimrod.
## **Deprecated** since version 0.8.2. Use the module `re` instead.
{.deprecated.}

## Currently this module is implemented by providing a wrapper around the
## `PRCE (Perl-Compatible Regular Expressions) <http://www.pcre.org>`_
## C library. This means that your application will depend on the PRCE
## library's licence when using this module, which should not be a problem
## though.
## PRCE's licence follows:
##
## .. include:: ../doc/regexprs.txt
##

# This is not just a convenient wrapper for the pcre library; the
# API will stay the same if the implementation should change.

import
  pcre, strutils

type
  EInvalidRegEx* = object of EInvalidValue
    ## is raised if the pattern is no valid regular expression.

const
  MaxSubpatterns* = 10
    ## defines the maximum number of subpatterns that can be captured.
    ## More subpatterns cannot be captured!

proc match*(s, pattern: string, matches: var openarray[string],
            start: int = 0): bool
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.

proc match*(s, pattern: string, start: int = 0): bool
  ## returns ``true`` if ``s`` matches the ``pattern`` beginning from ``start``.

proc matchLen*(s, pattern: string, matches: var openarray[string],
               start: int = 0): int
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.

proc find*(s, pattern: string, matches: var openarray[string],
           start: int = 0): bool
  ## returns ``true`` if ``pattern`` occurs in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches``.

proc find*(s, pattern: string, start: int = 0): bool
  ## returns ``true`` if ``pattern`` occurs in ``s``.

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
  

const ## common regular expressions
  reIdentifier* = r"\b[a-zA-Z_][a-zA-Z_0-9]*\b"  ## describes an identifier
  reNatural* = r"\b\d+\b" ## describes a natural number
  reInteger* = r"\b[-+]?\d+\b" ## describes an integer
  reHex* = r"\b0[xX][0-9a-fA-F]+\b" ## describes a hexadecimal number
  reBinary* = r"\b0[bB][01]+\b" ## describes a binary number (example: 0b11101)
  reOctal* = r"\b0[oO][0-7]+\b" ## describes an octal number (example: 0o777)
  reFloat* = r"\b[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\b"
    ## describes a floating point number
  reEmail* = r"\b[a-zA-Z0-9!#$%&'*+/=?^_`{|}~\-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)" &
             r"*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+(?:[a-zA-Z]{2}|com|org|" &
             r"net|gov|mil|biz|info|mobi|name|aero|jobs|museum)\b"
    ## describes a common email address
  reURL* = r"\b(http(s)?|ftp|gopher|telnet|file|notes|ms\-help):" &
           r"((//)|(\\\\))+[\w\d:#@%/;$()~_?\+\-\=\\\.\&]*\b"
    ## describes an URL
    
proc verbose*(pattern: string): string {.noSideEffect.} = 
  ## deletes whitespace from a pattern that is not escaped or in a character
  ## class. This is modelled after Perl's ``/x`` modifier. 
  result = ""
  var i = 0
  while i < pattern.len: 
    case pattern[i]
    of ' ', '\t': 
      inc i
    of '\\': 
      add result, '\\'
      add result, pattern[i+1]
      inc i, 2
    of '[': 
      while pattern[i] != ']' and pattern[i] != '\0': 
        add result, pattern[i]
        inc i
    else: 
      add result, pattern[i]
      inc i

