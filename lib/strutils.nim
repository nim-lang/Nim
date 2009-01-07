#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains various string utility routines.
## See the module `regexprs` for regular expression support.
## All the routines here are avaiable for the EMCAScript target
## too!

{.deadCodeElim: on.}

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

# copied from excpt.nim, because I don't want to make this template public
template newException(exceptn, message: expr): expr =
  block: # open a new scope
    var
      e: ref exceptn
    new(e)
    e.msg = message
    e


type
  TCharSet* = set[char] # for compability for Nim

const
  Whitespace* = {' ', '\t', '\v', '\r', '\l', '\f'}
    ## All the characters that count as whitespace.

  strStart* = 0 # this is only for bootstraping
                # XXX: remove this someday
  nl* = "\n"    # this is only for bootstraping XXX: remove this somehow

proc strip*(s: string): string {.noSideEffect.}
  ## Strips leading and trailing whitespace from `s`.

proc toLower*(s: string): string {.noSideEffect.}
  ## Converts `s` into lower case. This works only for the letters A-Z.
  ## See `unicode.toLower` for a version that works for any Unicode character.

proc toLower*(c: Char): Char {.noSideEffect.}
  ## Converts `c` into lower case. This works only for the letters A-Z.
  ## See `unicode.toLower` for a version that works for any Unicode character.

proc toUpper*(s: string): string {.noSideEffect.}
  ## Converts `s` into upper case. This works only for the letters a-z.
  ## See `unicode.toUpper` for a version that works for any Unicode character.

proc toUpper*(c: Char): Char {.noSideEffect.}
  ## Converts `c` into upper case. This works only for the letters a-z.
  ## See `unicode.toUpper` for a version that works for any Unicode character.

proc capitalize*(s: string): string {.noSideEffect.}
  ## Converts the first character of `s` into upper case.
  ## This works only for the letters a-z.

proc normalize*(s: string): string {.noSideEffect.}
  ## Normalizes the string `s`. That means to convert it to lower case and
  ## remove any '_'. This is needed for Nimrod identifiers for example.

proc findSubStr*(sub, s: string, start: int = 0): int {.noSideEffect.}
  ## Searches for `sub` in `s` starting at position `start`. Searching is
  ## case-sensitive. If `sub` is not in `s`, -1 is returned.

proc findSubStr*(sub: char, s: string, start: int = 0): int {.noSideEffect.}
  ## Searches for `sub` in `s` starting at position `start`. Searching is
  ## case-sensitive. If `sub` is not in `s`, -1 is returned.

proc findChars*(chars: set[char], s: string, start: int = 0): int {.noSideEffect.}
  ## Searches for `chars` in `s` starting at position `start`. If `s` contains
  ## none of the characters in `chars`, -1 is returned.

proc replaceStr*(s, sub, by: string): string {.noSideEffect.}
  ## Replaces `sub` in `s` by the string `by`.

proc replaceStr*(s: string, sub, by: char): string {.noSideEffect.}
  ## optimized version for characters.

proc deleteStr*(s: var string, first, last: int)
  ## Deletes in `s` the characters at position `first`..`last`. This modifies
  ## `s` itself, it does not return a copy.

proc toOctal*(c: char): string
  ## Converts a character `c` to its octal representation. The resulting
  ## string may not have a leading zero. Its length is always exactly 3.

iterator split*(s: string, seps: set[char] = Whitespace): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by a substring containing only `seps`.
  ## The seperator substrings are not returned in `sub`, nor are they part
  ## of `sub`.
  ## Examples::
  ##
  ##   for word in split("  this is an  example  "):
  ##     writeln(stdout, word)
  ##
  ## Results in::
  ##
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  ##   for word in split(";;this;is;an;;example;;;", {';'}):
  ##     writeln(stdout, word)
  ##
  ## produces in the same output.
  var
    first: int = 0
    last: int = 0
  assert(not ('\0' in seps))
  while last < len(s):
    while s[last] in seps: inc(last)
    first = last
    while last < len(s) and s[last] not_in seps: inc(last) # BUGFIX!
    yield copy(s, first, last-1)

iterator splitLines*(s: string): string =
  ## Splits the string `s` into its containing lines. Each newline
  ## combination (CR, LF, CR-LF) is supported. The result strings contain
  ## no trailing ``\n``.
  ##
  ## Example::
  ##
  ##   for line in lines("\nthis\nis\nan\n\nexample\n"):
  ##     writeln(stdout, line)
  ##
  ## Results in::
  ##
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

proc splitLinesSeq*(s: string): seq[string] {.noSideEffect.} =
  ## The same as `split`, but is a proc that returns a sequence of substrings.
  result = @[]
  for line in splitLines(s): add(result, line)

proc splitSeq*(s: string, seps: set[char] = Whitespace): seq[string] {.
  noSideEffect.}
  ## The same as `split`, but is a proc that returns a sequence of substrings.

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
  ## Same as ``findSubStr(c, s) >= 0``.

proc contains*(s, sub: string): bool {.noSideEffect.}
  ## Same as ``findSubStr(sub, s) >= 0``.

proc contains*(s: string, chars: set[char]): bool {.noSideEffect.}
  ## Same as ``findChars(s, chars) >= 0``.

proc toHex*(x: BiggestInt, len: int): string {.noSideEffect.}
  ## Converts `x` to its hexadecimal representation. The resulting string
  ## will be exactly `len` characters long. No prefix like ``0x``
  ## is generated. `x` is treated as unsigned value.

proc intToStr*(x: int, minchars: int = 1): string
  ## Converts `x` to its decimal representation. The resulting string
  ## will be minimally `minchars` characters long. This is achieved by
  ## adding leading zeros.

proc ParseInt*(s: string): int {.noSideEffect.}
  ## Parses a decimal integer value contained in `s`. If `s` is not
  ## a valid integer, `EInvalidValue` is raised.
  # XXX: make this biggestint!

proc ParseBiggestInt*(s: string): biggestInt {.noSideEffect.}
  ## Parses a decimal integer value contained in `s`. If `s` is not
  ## a valid integer, `EInvalidValue` is raised.

proc ParseFloat*(s: string): float {.noSideEffect.}
  ## Parses a decimal floating point value contained in `s`. If `s` is not
  ## a valid floating point number, `EInvalidValue` is raised. ``NAN``,
  ## ``INF``, ``-INF`` are also supported (case insensitive comparison).
  # XXX: make this biggestfloat.

# the stringify and format operators:
proc toString*[Ty](x: Ty): string
  ## This generic proc is the same as the stringify operator `$`.

proc `%` *(formatstr: string, a: openarray[string]): string {.noSideEffect.}
  ## The substitution operator performs string substitutions in `formatstr`
  ## and returns the modified `formatstr`.
  ##
  ## This is best explained by an example::
  ##
  ##   "$1 eats $2." % ["The cat", "fish"]
  ##
  ## Results in::
  ##
  ##   "The cat eats fish."
  ##
  ## The substitution variables (the thing after the ``$``)
  ## are enumerated from 1 to 9.
  ## Substitution variables can also be words (that is
  ## ``[A-Za-z_]+[A-Za-z0-9_]*``) in which case the arguments in `a` with even
  ## indices are keys and with odd indices are the corresponding values. Again
  ## an example::
  ##
  ##   "$animal eats $food." % ["animal", "The cat", "food", "fish"]
  ##
  ## Results in::
  ##
  ##   "The cat eats fish."
  ##
  ## The variables are compared with `cmpIgnoreStyle`. `EInvalidValue` is
  ## raised if an ill-formed format string has been passed to the `%` operator.

proc `%` *(formatstr, a: string): string {.noSideEffect.}
  ## This is the same as `formatstr % [a]`.

proc repeatChar*(count: int, c: Char = ' '): string
  ## Returns a string of length `count` consisting only of
  ## the character `c`.

proc startsWith*(s, prefix: string): bool {.noSideEffect.}
  ## Returns true iff ``s`` starts with ``prefix``.
  ## If ``prefix == ""`` true is returned.

proc endsWith*(s, suffix: string): bool {.noSideEffect.}
  ## Returns true iff ``s`` ends with ``suffix``.
  ## If ``suffix == ""`` true is returned.

# implementation

proc allCharsInSet*(s: string, theSet: TCharSet): bool =
  ## returns true iff each character of `s` is in the set `theSet`.
  for c in items(s):
    if not (c in theSet): return false
  return true

proc quoteIfContainsWhite*(s: string): string =
  ## returns ``'"' & s & '"'`` if `s` contains a space and does not
  ## start with a quote, else returns `s`
  if findChars({' ', '\t'}, s) >= 0 and s[0] != '"':
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
  var
    val: int
  result = newString(3)
  val = ord(c)
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
              # security whole ...
  return -1

proc `%`(formatstr: string, a: openarray[string]): string =
  # the format operator
  const
    PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\128'..'\255', '_'}
  result = ""
  var i = 0
  while i < len(formatstr):
    if formatstr[i] == '$':
      case formatstr[i+1] # again we use the fact that strings
                          # are zero-terminated here
      of '$':
        add result, '$'
        inc(i, 2)
      of '1'..'9':
        var j = 0
        inc(i) # skip $
        while formatstr[i] in {'0'..'9'}:
          j = j * 10 + ord(formatstr[i]) - ord('0')
          inc(i)
        add result, a[j - 1]
      of '{':
        var j = i+1
        while formatstr[j] notin {'\0', '}'}: inc(j)
        var x = findNormalized(copy(formatstr, i+2, j-1), a)
        if x >= 0 and x < high(a): add result, a[x+1]
        else: raise newException(EInvalidValue, "invalid format string")
        i = j+1
      of 'a'..'z', 'A'..'Z', '\128'..'\255', '_':
        var j = i+1
        while formatstr[j] in PatternChars: inc(j)
        var x = findNormalized(copy(formatstr, i+1, j-1), a)
        if x >= 0 and x < high(a): add result, a[x+1]
        else: raise newException(EInvalidValue, "invalid format string")
        i = j
      else: raise newException(EInvalidValue, "invalid format string")
    else:
      add result, formatstr[i]
      inc(i)

proc cmpIgnoreCase(a, b: string): int =
  # makes usage of the fact that strings are zero-terminated
  for i in 0..len(a)-1:
    var aa = toLower(a[i])
    var bb = toLower(b[i])
    result = ord(aa) - ord(bb)
    if result != 0: break

{.push checks: off, line_trace: off .} # this is a hot-spot in the compiler!
                                       # thus we compile without checks here

proc cmpIgnoreStyle(a, b: string): int =
  var
    i = 0
    j = 0
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

# ---------- splitting -----------------------------------------------------

proc splitSeq(s: string, seps: set[char]): seq[string] =
  result = @[]
  for sub in split(s, seps): add result, sub

# ---------------------------------------------------------------------------

proc strip(s: string): string =
  const
    chars: set[Char] = Whitespace
  var
    first = 0
    last = len(s)-1
  while s[first] in chars: inc(first)
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

proc findSubStrAux(sub, s: string, start: int, a: TSkipTable): int =
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

proc findSubStr(sub, s: string, start: int = 0): int =
  var a: TSkipTable
  preprocessSub(sub, a)
  result = findSubStrAux(sub, s, start, a)
  # slow linear search:
  #var
  #  i, j, M, N: int
  #M = len(sub)
  #N = len(s)
  #i = start
  #j = 0
  #if i >= N:
  #  result = -1
  #else:
  #  while True:
  #    if s[i] == sub[j]:
  #      Inc(i)
  #      Inc(j)
  #    else:
  #      i = i - j + 1
  #      j = 0
  #    if (j >= M):
  #      return i - M
  #    elif (i >= N):
  #      return -1


proc findSubStr(sub: char, s: string, start: int = 0): int =
  for i in start..len(s)-1:
    if sub == s[i]: return i
  return -1
 
proc findChars(chars: set[char], s: string, start: int = 0): int =
  for i in start..s.len-1:
    if s[i] in chars: return i
  return -1
  
proc contains(s: string, chars: set[char]): bool =
  return findChars(chars, s) >= 0

proc contains(s: string, c: char): bool =
  return findSubStr(c, s) >= 0

proc contains(s, sub: string): bool =
  return findSubStr(sub, s) >= 0

proc replaceStr(s, sub, by: string): string =
  var
    i, j: int
    a: TSkipTable
  result = ""
  preprocessSub(sub, a)
  i = 0
  while true:
    j = findSubStrAux(sub, s, i, a)
    if j < 0: break
    add result, copy(s, i, j - 1)
    add result, by
    i = j + len(sub)
  # copy the rest:
  add result, copy(s, i)

proc replaceStr(s: string, sub, by: char): string =
  result = newString(s.len)
  var i = 0
  while i < s.len:
    if s[i] == sub: result[i] = by
    else: result[i] = s[i]
    inc(i)

proc deleteStr(s: var string, first, last: int) =
  # example: "abc___uvwxyz\0"  (___ is to be deleted)
  # --> first == 3, last == 5
  # s[first..] = s[last+1..]
  var
    i = first
  while last+i+1 < len(s):
    s[i] = s[last+i+1]
    inc(i)
  setlen(s, len(s)-(last-first+1))

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

{.push overflowChecks: on.}
# this must be compiled with overflow checking turned on:
proc rawParseInt(s: string, index: var int): BiggestInt =
  # index contains the start position at proc entry; end position will be
  # an index before the proc returns; index = -1 on error (no number at all)
  # the problem here is that integers have an asymmetrical range: there is
  # one more valid negative than prositive integer. Thus we perform the
  # computation as a negative number and then change the sign at the end.
  var
    i: int = index # a local i is more efficient than accessing a var parameter
    sign: BiggestInt = -1
  if s[i] == '+':
    inc(i)
  elif s[i] == '-':
    inc(i)
    sign = 1
  if s[i] in {'0'..'9'}:
    result = 0
    while s[i] in {'0'..'9'}:
      result = result * 10 - (ord(s[i]) - ord('0'))
      inc(i)
      while s[i] == '_':
        inc(i)               # underscores are allowed and ignored
    result = result * sign
    index = i                # store index back
  else:
    index = -1

{.pop.} # overflowChecks

proc parseInt(s: string): int =
  var
    index: int = 0
    res = rawParseInt(s, index)
  if index == -1:
    raise newException(EInvalidValue, "invalid integer: " & s)
  elif (sizeof(int) <= 4) and
      ((res < low(int)) or (res > high(int))):
    raise newException(EOverflow, "overflow")
  else:
    result = int(res) # convert to smaller integer type

proc ParseBiggestInt(s: string): biggestInt =
  var
    index: int = 0
  result = rawParseInt(s, index)
  if index == -1:
    raise newException(EInvalidValue, "invalid integer: " & s)

proc ParseFloat(s: string): float =
  var
    esign = 1.0
    sign = 1.0
    exponent, i: int
    flags: int
  result = 0.0
  if s[i] == '+': inc(i)
  elif s[i] == '-':
    sign = -1.0
    inc(i)
  if s[i] == 'N' or s[i] == 'n':
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if s[i+3] == '\0': return NaN
    raise newException(EInvalidValue, "invalid float: " & s)
  if s[i] == 'I' or s[i] == 'i':
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if s[i+3] == '\0': return Inf*sign
    raise newException(EInvalidValue, "invalid float: " & s)
  while s[i] in {'0'..'9'}:
    # Read integer part
    flags = flags or 1
    result = result * 10.0 + toFloat(ord(s[i]) - ord('0'))
    inc(i)
    while s[i] == '_': inc(i)
  # Decimal?
  if s[i] == '.':
    var hd = 1.0
    inc(i)
    while s[i] in {'0'..'9'}:
      # Read fractional part
      flags = flags or 2
      result = result * 10.0 + toFloat(ord(s[i]) - ord('0'))
      hd = hd * 10.0
      inc(i)
      while s[i] == '_': inc(i)
    result = result / hd # this complicated way preserves precision
  # Again, read integer and fractional part
  if flags == 0:
    raise newException(EInvalidValue, "invalid float: " & s)
  # Exponent?
  if s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+':
      inc(i)
    elif s[i] == '-':
      esign = -1.0
      inc(i)
    if s[i] notin {'0'..'9'}:
      raise newException(EInvalidValue, "invalid float: " & s)
    while s[i] in {'0'..'9'}:
      exponent = exponent * 10 + ord(s[i]) - ord('0')
      inc(i)
      while s[i] == '_': inc(i)
  # Calculate Exponent
  var hd = 1.0
  for j in 1..exponent:
    hd = hd * 10.0
  if esign > 0.0: result = result * hd
  else:           result = result / hd
  # Not all characters are read?
  if s[i] != '\0': raise newException(EInvalidValue, "invalid float: " & s)
  # evaluate sign
  result = result * sign

proc toOct*(x: BiggestInt, len: int): string =
  ## converts `x` into its octal representation. The resulting string is
  ## always `len` characters long. No leading ``0c`` prefix is generated.
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

proc escape*(s: string, prefix, suffix = "\""): string =
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

proc editDistance*(a, b: string): int =
  ## returns the edit distance between `s` and `t`. This uses the Levenshtein
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
