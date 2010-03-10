#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains various string utility routines.
## See the module `regexprs` for regular expression support.

import parseutils

{.deadCodeElim: on.}

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

type
  TCharSet* = set[char] # for compatibility with Nim

const
  Whitespace* = {' ', '\t', '\v', '\r', '\l', '\f'}
    ## All the characters that count as whitespace.
    
  Letters* = {'A'..'Z', 'a'..'z'}
    ## the set of letters
  
  Digits* = {'0'..'9'}
    ## the set of digits
  
  IdentChars* = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## the set of characters an identifier can consist of
  
  IdentStartChars* = {'a'..'z', 'A'..'Z', '_'}
    ## the set of characters an identifier can start with

proc `%` *(formatstr: string, a: openarray[string]): string {.noSideEffect.}
  ## The `substitution`:idx: operator performs string substitutions in
  ## `formatstr` and returns a modified `formatstr`. This is often called
  ## `string interpolation`:idx:.
  ##
  ## This is best explained by an example:
  ##
  ## .. code-block:: nimrod
  ##   "$1 eats $2." % ["The cat", "fish"]
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   "The cat eats fish."
  ##
  ## The substitution variables (the thing after the ``$``) are enumerated
  ## from 1 to ``a.len``.
  ## The notation ``$#`` can be used to refer to the next substitution variable:
  ##
  ## .. code-block:: nimrod
  ##   "$# eats $#." % ["The cat", "fish"]
  ##
  ## Substitution variables can also be words (that is
  ## ``[A-Za-z_]+[A-Za-z0-9_]*``) in which case the arguments in `a` with even
  ## indices are keys and with odd indices are the corresponding values.
  ## An example:
  ##
  ## .. code-block:: nimrod
  ##   "$animal eats $food." % ["animal", "The cat", "food", "fish"]
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   "The cat eats fish."
  ##
  ## The variables are compared with `cmpIgnoreStyle`. `EInvalidValue` is
  ## raised if an ill-formed format string has been passed to the `%` operator.

proc `%` *(formatstr, a: string): string {.noSideEffect.}
  ## This is the same as ``formatstr % [a]``.

proc addf*(s: var string, formatstr: string, a: openarray[string])
  ## The same as ``add(s, formatstr % a)``, but more efficient.

proc strip*(s: string, leading = true, trailing = true): string {.noSideEffect.}
  ## Strips whitespace from `s` and returns the resulting string.
  ## If `leading` is true, leading whitespace is stripped.
  ## If `trailing` is true, trailing whitespace is stripped.

proc toLower*(s: string): string {.noSideEffect, procvar.}
  ## Converts `s` into lower case. This works only for the letters A-Z.
  ## See `unicode.toLower` for a version that works for any Unicode character.

proc toLower*(c: Char): Char {.noSideEffect, procvar.}
  ## Converts `c` into lower case. This works only for the letters A-Z.
  ## See `unicode.toLower` for a version that works for any Unicode character.

proc toUpper*(s: string): string {.noSideEffect, procvar.}
  ## Converts `s` into upper case. This works only for the letters a-z.
  ## See `unicode.toUpper` for a version that works for any Unicode character.

proc toUpper*(c: Char): Char {.noSideEffect, procvar.}
  ## Converts `c` into upper case. This works only for the letters a-z.
  ## See `unicode.toUpper` for a version that works for any Unicode character.

proc capitalize*(s: string): string {.noSideEffect, procvar.}
  ## Converts the first character of `s` into upper case.
  ## This works only for the letters a-z.

proc normalize*(s: string): string {.noSideEffect, procvar.}
  ## Normalizes the string `s`. That means to convert it to lower case and
  ## remove any '_'. This is needed for Nimrod identifiers for example.

proc find*(s, sub: string, start: int = 0): int {.noSideEffect.}
  ## Searches for `sub` in `s` starting at position `start`. Searching is
  ## case-sensitive. If `sub` is not in `s`, -1 is returned.

proc find*(s: string, sub: char, start: int = 0): int {.noSideEffect.}
  ## Searches for `sub` in `s` starting at position `start`. Searching is
  ## case-sensitive. If `sub` is not in `s`, -1 is returned.

proc find*(s: string, chars: set[char], start: int = 0): int {.noSideEffect.}
  ## Searches for `chars` in `s` starting at position `start`. If `s` contains
  ## none of the characters in `chars`, -1 is returned.

proc replaceStr*(s, sub, by: string): string {.noSideEffect, deprecated.}
  ## Replaces `sub` in `s` by the string `by`.
  ## **Deprecated since version 0.8.0**: Use `replace` instead.

proc replaceStr*(s: string, sub, by: char): string {.noSideEffect, deprecated.}
  ## optimized version for characters.
  ## **Deprecated since version 0.8.0**: Use `replace` instead.

proc deleteStr*(s: var string, first, last: int) {.deprecated.}
  ## Deletes in `s` the characters at position `first`..`last`. This modifies
  ## `s` itself, it does not return a copy.
  ## **Deprecated since version 0.8.0**: Use `delete` instead.

proc toOctal*(c: char): string
  ## Converts a character `c` to its octal representation. The resulting
  ## string may not have a leading zero. Its length is always exactly 3.

iterator split*(s: string, seps: set[char] = Whitespace): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by a substring containing only `seps`.
  ## Examples:
  ##
  ## .. code-block:: nimrod
  ##   for word in split("  this is an  example  "):
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
  ##   for word in split(";;this;is;an;;example;;;", {';'}):
  ##     writeln(stdout, word)
  ##
  ## produces the same output.
  var last = 0
  assert(not ('\0' in seps))
  while last < len(s):
    while s[last] in seps: inc(last)
    var first = last
    while last < len(s) and s[last] not_in seps: inc(last) # BUGFIX!
    if first <= last-1:
      yield copy(s, first, last-1)

iterator split*(s: string, sep: char): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by the character `sep`.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   for word in split(";;this;is;an;;example;;;", ';'):
  ##     writeln(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   ""
  ##   ""
  ##   "this"
  ##   "is"
  ##   "an"
  ##   ""
  ##   "example"
  ##   ""
  ##   ""
  ##   ""
  ##
  var last = 0
  assert('\0' != sep)
  if len(s) > 0:
    # `<=` is correct here for the edge cases!
    while last <= len(s):
      var first = last
      while last < len(s) and s[last] != sep: inc(last)
      yield copy(s, first, last-1)
      inc(last)

iterator splitLines*(s: string): string =
  ## Splits the string `s` into its containing lines. Every newline
  ## combination (CR, LF, CR-LF) is supported. The result strings contain
  ## no trailing ``\n``.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   for line in lines("\nthis\nis\nan\n\nexample\n"):
  ##     writeln(stdout, line)
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   ""
  ##   "this"
  ##   "is"
  ##   "an"
  ##   ""
  ##   "example"
  ##   ""
  var first = 0
  var last = 0
  while true:
    while s[last] notin {'\0', '\c', '\l'}: inc(last)
    yield copy(s, first, last-1)
    # skip newlines:
    if s[last] == '\l': inc(last)
    elif s[last] == '\c':
      inc(last)
      if s[last] == '\l': inc(last)
    else: break # was '\0'
    first = last

proc splitLinesSeq*(s: string): seq[string] {.noSideEffect, deprecated.} =
  ## The same as `splitLines`, but is a proc that returns a sequence 
  ## of substrings.
  ## **Deprecated since version 0.8.0**: Use `splitLines` instead.
  accumulateResult(splitLines(s))

proc splitSeq*(s: string, seps: set[char] = Whitespace): seq[string] {.
  noSideEffect, deprecated.} =
  ## The same as `split`, but is a proc that returns a sequence of substrings.
  ## **Deprecated since version 0.8.0**: Use `split` instead.
  accumulateResult(split(s, seps))

proc splitSeq*(s: string, sep: char): seq[string] {.noSideEffect, 
                                                    deprecated.} =
  ## The same as `split`, but is a proc that returns a sequence of substrings.
  ## **Deprecated since version 0.8.0**: Use `split` instead.
  accumulateResult(split(s, sep))

proc splitLines*(s: string): seq[string] {.noSideEffect.} =
  ## The same as the `splitLines` iterator, but is a proc that returns a 
  ## sequence of substrings.
  accumulateResult(splitLines(s))

proc split*(s: string, seps: set[char] = Whitespace): seq[string] {.
  noSideEffect.} =
  ## The same as the `split` iterator, but is a proc that returns a
  ## sequence of substrings.
  accumulateResult(split(s, seps))

proc split*(s: string, sep: char): seq[string] {.noSideEffect.} =
  ## The same as the `split` iterator, but is a proc that returns a sequence
  ## of substrings.
  accumulateResult(split(s, sep))

proc cmpIgnoreCase*(a, b: string): int {.noSideEffect.}
  ## Compares two strings in a case insensitive manner. Returns:
  ##
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b

proc cmpIgnoreStyle*(a, b: string): int {.noSideEffect.}
  ## Compares two strings normalized (i.e. case and
  ## underscores do not matter). Returns:
  ##
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b

proc contains*(s: string, c: char): bool {.noSideEffect.}
  ## Same as ``find(s, c) >= 0``.

proc contains*(s, sub: string): bool {.noSideEffect.}
  ## Same as ``find(s, sub) >= 0``.

proc contains*(s: string, chars: set[char]): bool {.noSideEffect.}
  ## Same as ``find(s, chars) >= 0``.

proc toHex*(x: BiggestInt, len: int): string {.noSideEffect.}
  ## Converts `x` to its hexadecimal representation. The resulting string
  ## will be exactly `len` characters long. No prefix like ``0x``
  ## is generated. `x` is treated as an unsigned value.

proc intToStr*(x: int, minchars: int = 1): string
  ## Converts `x` to its decimal representation. The resulting string
  ## will be minimally `minchars` characters long. This is achieved by
  ## adding leading zeros.

proc ParseInt*(s: string): int {.noSideEffect, procvar.}
  ## Parses a decimal integer value contained in `s`. If `s` is not
  ## a valid integer, `EInvalidValue` is raised.

proc ParseBiggestInt*(s: string): biggestInt {.noSideEffect, procvar.}
  ## Parses a decimal integer value contained in `s`. If `s` is not
  ## a valid integer, `EInvalidValue` is raised.

proc ParseFloat*(s: string): float {.noSideEffect, procvar.}
  ## Parses a decimal floating point value contained in `s`. If `s` is not
  ## a valid floating point number, `EInvalidValue` is raised. ``NAN``,
  ## ``INF``, ``-INF`` are also supported (case insensitive comparison).

proc ParseHexInt*(s: string): int {.noSideEffect, procvar.} 
  ## Parses a hexadecimal integer value contained in `s`. If `s` is not
  ## a valid integer, `EInvalidValue` is raised. `s` can have one of the
  ## following optional prefixes: ``0x``, ``0X``, ``#``. 
  ## Underscores within `s` are ignored.

# the stringify and format operators:
proc toString*[Ty](x: Ty): string {.deprecated.}
  ## This generic proc is the same as the stringify operator `$`.
  ##
  ## **Deprecated since version 0.8.2:** Use `$` instead.

proc repeatChar*(count: int, c: Char = ' '): string
  ## Returns a string of length `count` consisting only of
  ## the character `c`.

proc startsWith*(s, prefix: string): bool {.noSideEffect.}
  ## Returns true iff ``s`` starts with ``prefix``.
  ## If ``prefix == ""`` true is returned.

proc endsWith*(s, suffix: string): bool {.noSideEffect.}
  ## Returns true iff ``s`` ends with ``suffix``.
  ## If ``suffix == ""`` true is returned.

proc addSep*(dest: var string, sep = ", ", startLen = 0) {.noSideEffect,
                                                           inline.} = 
  ## A shorthand for: 
  ## 
  ## .. code-block:: nimrod
  ##   if dest.len > startLen: add(dest, sep)
  ## 
  ## This is often useful for generating some code where the items need to
  ## be *separated* by `sep`. `sep` is only added if `dest` is longer than
  ## `startLen`. The following example creates a string describing
  ## an array of integers:  
  ## 
  ## .. code-block:: nimrod
  ##   var arr = "["
  ##   for x in items([2, 3, 5, 7, 11]):
  ##     addSep(arr, startLen=len("["))
  ##     add(arr, $x)
  ##   add(arr, "]")
  if dest.len > startLen: add(dest, sep)

proc allCharsInSet*(s: string, theSet: TCharSet): bool =
  ## returns true iff each character of `s` is in the set `theSet`.
  for c in items(s):
    if c notin theSet: return false
  return true

proc quoteIfContainsWhite*(s: string): string =
  ## returns ``'"' & s & '"'`` if `s` contains a space and does not
  ## start with a quote, else returns `s`
  if find(s, {' ', '\t'}) >= 0 and s[0] != '"':
    result = '"' & s & '"'
  else:
    result = s

proc startsWith(s, prefix: string): bool =
  var i = 0
  while true:
    if prefix[i] == '\0': return true
    if s[i] != prefix[i]: return false
    inc(i)

proc endsWith(s, suffix: string): bool =
  var
    i = 0
    j = len(s) - len(suffix)
  while true:
    if suffix[i] == '\0': return true
    if s[i+j] != suffix[i]: return false
    inc(i)

when false:
  proc abbrev(s: string, possibilities: openarray[string]): int = 
    ## returns the index of the first item in `possibilities` if not
    ## ambiguous; -1 if no item has been found; -2 if multiple items
    ## match.
    result = -1 # none found
    for i in 0..possibilities.len-1: 
      if possibilities[i].startsWith(s): 
        if result >= 0: return -2 # ambiguous
        result = i

proc repeatChar(count: int, c: Char = ' '): string =
  result = newString(count)
  for i in 0..count-1:
    result[i] = c

proc intToStr(x: int, minchars: int = 1): string =
  result = $abs(x)
  for i in 1 .. minchars - len(result):
    result = '0' & result
  if x < 0:
    result = '-' & result

proc toString[Ty](x: Ty): string = return $x

proc toOctal(c: char): string =
  result = newString(3)
  var val = ord(c)
  for i in countdown(2, 0):
    result[i] = Chr(val mod 8 + ord('0'))
    val = val div 8

proc `%`(formatstr: string, a: string): string =
  return formatstr % [a]

proc findNormalized(x: string, inArray: openarray[string]): int =
  var i = 0
  while i < high(inArray):
    if cmpIgnoreStyle(x, inArray[i]) == 0: return i
    inc(i, 2) # incrementing by 1 would probably result in a
              # security hole ...
  return -1

proc addf(s: var string, formatstr: string, a: openarray[string]) =
  const PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\128'..'\255', '_'}
  var i = 0
  var num = 0
  while i < len(formatstr):
    if formatstr[i] == '$':
      case formatstr[i+1] # again we use the fact that strings
                          # are zero-terminated here
      of '#':
        add s, a[num]
        inc i, 2
        inc num
      of '$':
        add s, '$'
        inc(i, 2)
      of '1'..'9':
        var j = 0
        inc(i) # skip $
        while formatstr[i] in {'0'..'9'}:
          j = j * 10 + ord(formatstr[i]) - ord('0')
          inc(i)
        num = j
        add s, a[j - 1]
      of '{':
        var j = i+1
        while formatstr[j] notin {'\0', '}'}: inc(j)
        var x = findNormalized(copy(formatstr, i+2, j-1), a)
        if x >= 0 and x < high(a): add s, a[x+1]
        else: raise newException(EInvalidValue, "invalid format string")
        i = j+1
      of 'a'..'z', 'A'..'Z', '\128'..'\255', '_':
        var j = i+1
        while formatstr[j] in PatternChars: inc(j)
        var x = findNormalized(copy(formatstr, i+1, j-1), a)
        if x >= 0 and x < high(a): add s, a[x+1]
        else: raise newException(EInvalidValue, "invalid format string")
        i = j
      else: raise newException(EInvalidValue, "invalid format string")
    else:
      add s, formatstr[i]
      inc(i)
  
proc `%`(formatstr: string, a: openarray[string]): string =
  result = ""
  addf(result, formatstr, a)

proc cmpIgnoreCase(a, b: string): int =
  var i = 0
  while i < a.len and i < b.len:
    result = ord(toLower(a[i])) - ord(toLower(b[i]))
    if result != 0: return
    inc(i)
  result = a.len - b.len


{.push checks: off, line_trace: off .} # this is a hot-spot in the compiler!
                                       # thus we compile without checks here

proc cmpIgnoreStyle(a, b: string): int =
  var i = 0
  var j = 0
  while True:
    while a[i] == '_': inc(i)
    while b[j] == '_': inc(j) # BUGFIX: typo
    var aa = toLower(a[i])
    var bb = toLower(b[j])
    result = ord(aa) - ord(bb)
    if result != 0 or aa == '\0': break
    inc(i)
    inc(j)

{.pop.}

# ---------------------------------------------------------------------------

proc join*(a: openArray[string], sep: string): string =
  ## concatenates all strings in `a` separating them with `sep`.
  if len(a) > 0:
    var L = sep.len * (a.len-1)
    for i in 0..high(a): inc(L, a[i].len)
    result = newString(L)
    setLen(result, 0)
    add(result, a[0])
    for i in 1..high(a):
      add(result, sep)
      add(result, a[i])
  else:
    result = ""
  
proc join*(a: openArray[string]): string =
  ## concatenates all strings in `a`.
  if len(a) > 0:
    var L = 0
    for i in 0..high(a): inc(L, a[i].len)
    result = newString(L)
    setLen(result, 0)
    for i in 0..high(a): add(result, a[i])
  else:
    result = ""

proc strip(s: string, leading = true, trailing = true): string =
  const
    chars: set[Char] = Whitespace
  var
    first = 0
    last = len(s)-1
  if leading: 
    while s[first] in chars: inc(first)
  if trailing:
    while last >= 0 and s[last] in chars: dec(last)
  result = copy(s, first, last)

proc toLower(c: Char): Char =
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

proc toLower(s: string): string =
  result = newString(len(s))
  for i in 0..len(s) - 1:
    result[i] = toLower(s[i])

proc toUpper(c: Char): Char =
  if c in {'a'..'z'}:
    result = Chr(Ord(c) - (Ord('a') - Ord('A')))
  else:
    result = c

proc toUpper(s: string): string =
  result = newString(len(s))
  for i in 0..len(s) - 1:
    result[i] = toUpper(s[i])

proc capitalize(s: string): string =
  result = toUpper(s[0]) & copy(s, 1)

proc normalize(s: string): string =
  result = ""
  for i in 0..len(s) - 1:
    if s[i] in {'A'..'Z'}:
      add result, Chr(Ord(s[i]) + (Ord('a') - Ord('A')))
    elif s[i] != '_':
      add result, s[i]

type
  TSkipTable = array[Char, int]

proc preprocessSub(sub: string, a: var TSkipTable) =
  var m = len(sub)
  for i in 0..0xff: a[chr(i)] = m+1
  for i in 0..m-1: a[sub[i]] = m-i

proc findAux(s, sub: string, start: int, a: TSkipTable): int =
  # fast "quick search" algorithm:
  var
    m = len(sub)
    n = len(s)
  # search:
  var j = start
  while j <= n - m:
    block match:
      for k in 0..m-1:
        if sub[k] != s[k+j]: break match
      return j
    inc(j, a[s[j+m]])
  return -1

proc find(s, sub: string, start: int = 0): int =
  var a: TSkipTable
  preprocessSub(sub, a)
  result = findAux(s, sub, start, a)

proc find(s: string, sub: char, start: int = 0): int =
  for i in start..len(s)-1:
    if sub == s[i]: return i
  return -1
 
proc find(s: string, chars: set[char], start: int = 0): int =
  for i in start..s.len-1:
    if s[i] in chars: return i
  return -1 

proc contains(s: string, chars: set[char]): bool =
  return find(s, chars) >= 0

proc contains(s: string, c: char): bool =
  return find(s, c) >= 0

proc contains(s, sub: string): bool =
  return find(s, sub) >= 0

proc replace*(s, sub, by: string): string =
  ## Replaces `sub` in `s` by the string `by`.
  var a: TSkipTable
  result = ""
  preprocessSub(sub, a)
  var i = 0
  while true:
    var j = findAux(s, sub, i, a)
    if j < 0: break
    add result, copy(s, i, j - 1)
    add result, by
    i = j + len(sub)
  # copy the rest:
  add result, copy(s, i)

proc replace*(s: string, sub, by: char): string =
  ## optimized version for characters.
  result = newString(s.len)
  var i = 0
  while i < s.len:
    if s[i] == sub: result[i] = by
    else: result[i] = s[i]
    inc(i)

proc delete*(s: var string, first, last: int) =
  ## Deletes in `s` the characters at position `first`..`last`. This modifies
  ## `s` itself, it does not return a copy.
  var i = first
  # example: "abc___uvwxyz\0"  (___ is to be deleted)
  # --> first == 3, last == 5
  # s[first..] = s[last+1..]
  while last+i+1 < len(s):
    s[i] = s[last+i+1]
    inc(i)
  setlen(s, len(s)-(last-first+1))

proc replaceStr(s, sub, by: string): string = return replace(s, sub, by)
proc replaceStr(s: string, sub, by: char): string = return replace(s, sub, by)
proc deleteStr*(s: var string, first, last: int) = delete(s, first, last)

# parsing numbers:

proc toHex(x: BiggestInt, len: int): string =
  const
    HexChars = "0123456789ABCDEF"
  var
    shift: BiggestInt
  result = newString(len)
  for j in countdown(len-1, 0):
    result[j] = HexChars[toU32(x shr shift) and 0xF'i32]
    shift = shift + 4

proc parseInt(s: string): int =
  var L = parseutils.parseInt(s, result, 0)
  if L != s.len: raise newException(EInvalidValue, "invalid integer: " & s)

proc ParseBiggestInt(s: string): biggestInt =
  var L = parseutils.parseBiggestInt(s, result, 0)
  if L != s.len: raise newException(EInvalidValue, "invalid integer: " & s)

proc ParseOctInt*(s: string): int =
  var i = 0
  if s[i] == '0' and (s[i+1] == 'o' or s[i+1] == 'O'): inc(i, 2)
  while true: 
    case s[i]
    of '_': inc(i)
    of '0'..'7': 
      result = result shl 3 or (ord(s[i]) - ord('0'))
      inc(i)
    of '\0': break
    else: raise newException(EInvalidValue, "invalid integer: " & s)

proc ParseHexInt(s: string): int = 
  var i = 0
  if s[i] == '0' and (s[i+1] == 'x' or s[i+1] == 'X'): inc(i, 2)
  elif s[i] == '#': inc(i)
  while true: 
    case s[i]
    of '_': inc(i)
    of '0'..'9': 
      result = result shl 4 or (ord(s[i]) - ord('0'))
      inc(i)
    of 'a'..'f': 
      result = result shl 4 or (ord(s[i]) - ord('a') + 10)
      inc(i)
    of 'A'..'F': 
      result = result shl 4 or (ord(s[i]) - ord('A') + 10)
      inc(i)
    of '\0': break
    else: raise newException(EInvalidValue, "invalid integer: " & s)

proc ParseFloat(s: string): float =
  var L = parseutils.parseFloat(s, result, 0)
  if L != s.len: raise newException(EInvalidValue, "invalid float: " & s)

proc toOct*(x: BiggestInt, len: int): string =
  ## converts `x` into its octal representation. The resulting string is
  ## always `len` characters long. No leading ``0o`` prefix is generated.
  var
    mask: BiggestInt = 7
    shift: BiggestInt = 0
  assert(len > 0)
  result = newString(len)
  for j in countdown(len-1, 0):
    result[j] = chr(int((x and mask) shr shift) + ord('0'))
    shift = shift + 3
    mask = mask shl 3

proc toBin*(x: BiggestInt, len: int): string =
  ## converts `x` into its binary representation. The resulting string is
  ## always `len` characters long. No leading ``0b`` prefix is generated.
  var
    mask: BiggestInt = 1
    shift: BiggestInt = 0
  assert(len > 0)
  result = newString(len)
  for j in countdown(len-1, 0):
    result[j] = chr(int((x and mask) shr shift) + ord('0'))
    shift = shift + 1
    mask = mask shl 1

proc insertSep*(s: string, sep = '_', digits = 3): string = 
  ## inserts the separator `sep` after `digits` digits from right to left.
  ## Even though the algorithm works with any string `s`, it is only useful 
  ## if `s` contains a number.
  ## Example: ``insertSep("1000000") == "1_000_000"`` 
  var L = (s.len-1) div digits + s.len
  result = newString(L)
  var j = 0
  dec(L)
  for i in countdown(len(s)-1, 0): 
    if j == digits: 
      result[L] = sep
      dec(L)
      j = 0
    result[L] = s[i]
    inc(j)
    dec(L)

proc escape*(s: string, prefix = "\"", suffix = "\""): string =
  ## Escapes a string `s`. This does these operations (at the same time):
  ## * replaces any ``\`` by ``\\``
  ## * replaces any ``'`` by ``\'``
  ## * replaces any ``"`` by ``\"``
  ## * replaces any other character in the set ``{'\0'..'\31', '\128'..'\255'}``
  ##   by ``\xHH`` where ``HH`` is its hexadecimal value.
  ## The procedure has been designed so that its output is usable for many
  ## different common syntaxes. The resulting string is prefixed with
  ## ``prefix`` and suffixed with ``suffix``. Both may be empty strings.
  result = prefix
  for c in items(s):
    case c
    of '\0'..'\31', '\128'..'\255':
      add(result, '\\')
      add(result, toHex(ord(c), 2))
    of '\\': add(result, "\\\\")
    of '\'': add(result, "\\'")
    of '\"': add(result, "\\\"")
    else: add(result, c)
  add(result, suffix)

proc validEmailAddress*(s: string): bool = 
  ## returns true if `s` seems to be a valid e-mail address. 
  ## The checking also uses a domain list.
  ## Note: This will be moved into another module soon.
  const
    chars = Letters + Digits + {'!','#','$','%','&',
      '\'','*','+','/','=','?','^','_','`','{','}','|','~','-','.'}
  var i = 0
  if s[i] notin chars or s[i] == '.': return false
  while s[i] in chars: 
    if s[i] == '.' and s[i+1] == '.': return false
    inc(i)
  if s[i] != '@': return false
  var j = len(s)-1
  if s[j] notin letters: return false
  while j >= i and s[j] in letters: dec(j)
  inc(i) # skip '@'
  while s[i] in {'0'..'9', 'a'..'z', '-', '.'}: inc(i) 
  if s[i] != '\0': return false
  
  var x = copy(s, j+1)
  if len(x) == 2 and x[0] in Letters and x[1] in Letters: return true
  case toLower(x)
  of "com", "org", "net", "gov", "mil", "biz", "info", "mobi", "name",
     "aero", "jobs", "museum": return true
  return false
  
proc validIdentifier*(s: string): bool = 
  ## returns true if `s` is a valid identifier. A valid identifier starts
  ## with a character of the set `IdentStartChars` and is followed by any
  ## number of characters of the set `IdentChars`.
  if s[0] in IdentStartChars:
    for i in 1..s.len-1:
      if s[i] notin IdentChars: return false
    return true
  
proc editDistance*(a, b: string): int =
  ## returns the edit distance between `a` and `b`. This uses the Levenshtein
  ## distance algorithm with only a linear memory overhead. This implementation
  ## is highly optimized!
  var len1 = a.len
  var len2 = b.len
  if len1 > len2:
    # make `b` the longer string
    return editDistance(b, a)

  # strip common prefix:
  var s = 0
  while a[s] == b[s] and a[s] != '\0':
    inc(s)
    dec(len1)
    dec(len2)
  # strip common suffix:
  while len1 > 0 and len2 > 0 and a[s+len1-1] == b[s+len2-1]:
    dec(len1)
    dec(len2)
  # trivial cases:
  if len1 == 0: return len2
  if len2 == 0: return len1

  # another special case:
  if len1 == 1:
    for j in s..len2-1:
      if a[s] == b[j]: return len2 - 1
    return len2

  inc(len1)
  inc(len2)
  var half = len1 shr 1
  # initalize first row:
  #var row = cast[ptr array[0..high(int) div 8, int]](alloc(len2 * sizeof(int)))
  var row: seq[int]
  newSeq(row, len2)
  var e = s + len2 - 1 # end marker
  for i in 1..len2 - half - 1: row[i] = i
  row[0] = len1 - half - 1
  for i in 1 .. len1 - 1:
    var char1 = a[i + s - 1]
    var char2p: int
    var D, x: int
    var p: int
    if i >= len1 - half:
      # skip the upper triangle:
      var offset = i - len1 + half
      char2p = offset
      p = offset
      var c3 = row[p] + ord(char1 != b[s + char2p])
      inc(p)
      inc(char2p)
      x = row[p] + 1
      D = x
      if x > c3: x = c3
      row[p] = x
      inc(p)
    else:
      p = 1
      char2p = 0
      D = i
      x = i
    if i <= half + 1:
      # skip the lower triangle:
      e = len2 + i - half - 2
    # main:
    while p <= e:
      dec(D)
      var c3 = D + ord(char1 != b[char2p + s])
      inc(char2p)
      inc(x)
      if x > c3: x = c3
      D = row[p] + 1
      if x > D: x = D
      row[p] = x
      inc(p)
    # lower triangle sentinel:
    if i <= half:
      dec(D)
      var c3 = D + ord(char1 != b[char2p + s])
      inc(x)
      if x > c3: x = c3
      row[p] = x
  result = row[e]
  #dealloc(row)

{.pop.}
