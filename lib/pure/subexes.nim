#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim support for `substitution expressions`:idx: (`subex`:idx:).
##
## .. include:: ../../doc/subexes.txt
##

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

from strutils import parseInt, cmpIgnoreStyle, Digits
include "system/inclrtl"


proc findNormalized(x: string, inArray: openarray[string]): int =
  var i = 0
  while i < high(inArray):
    if cmpIgnoreStyle(x, inArray[i]) == 0: return i
    inc(i, 2) # incrementing by 1 would probably lead to a
              # security hole...
  return -1

type
  SubexError* = object of ValueError ## exception that is raised for
                                     ## an invalid subex

proc raiseInvalidFormat(msg: string) {.noinline.} =
  raise newException(SubexError, "invalid format string: " & msg)

type
  FormatParser = object {.pure, final.}
    when defined(js):
      f: string # we rely on the '\0' terminator
                # which JS's native string doesn't have
    else:
      f: cstring
    num, i, lineLen: int

template call(x: untyped): untyped =
  p.i = i
  x
  i = p.i

template callNoLineLenTracking(x: untyped): untyped =
  let oldLineLen = p.lineLen
  p.i = i
  x
  i = p.i
  p.lineLen = oldLineLen

proc getFormatArg(p: var FormatParser, a: openArray[string]): int =
  const PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\128'..'\255', '_'}
  var i = p.i
  var f = p.f
  case f[i]
  of '#':
    result = p.num
    inc i
    inc p.num
  of '1'..'9', '-':
    var j = 0
    var negative = f[i] == '-'
    if negative: inc i
    while f[i] in Digits:
      j = j * 10 + ord(f[i]) - ord('0')
      inc i
    result = if not negative: j-1 else: a.len-j
  of 'a'..'z', 'A'..'Z', '\128'..'\255', '_':
    var name = ""
    while f[i] in PatternChars:
      name.add(f[i])
      inc(i)
    result = findNormalized(name, a)+1
  of '$':
    inc(i)
    call:
      result = getFormatArg(p, a)
    result = parseInt(a[result])-1
  else:
    raiseInvalidFormat("'#', '$', number or identifier expected")
  if result >=% a.len: raiseInvalidFormat("index out of bounds: " & $result)
  p.i = i

proc scanDollar(p: var FormatParser, a: openarray[string], s: var string) {.
  noSideEffect.}

proc emitChar(p: var FormatParser, x: var string, ch: char) {.inline.} =
  x.add(ch)
  if ch == '\L': p.lineLen = 0
  else: inc p.lineLen

proc emitStrLinear(p: var FormatParser, x: var string, y: string) {.inline.} =
  for ch in items(y): emitChar(p, x, ch)

proc emitStr(p: var FormatParser, x: var string, y: string) {.inline.} =
  x.add(y)
  inc p.lineLen, y.len

proc scanQuote(p: var FormatParser, x: var string, toAdd: bool) =
  var i = p.i+1
  var f = p.f
  while true:
    if f[i] == '\'':
      inc i
      if f[i] != '\'': break
      inc i
      if toAdd: emitChar(p, x, '\'')
    elif f[i] == '\0': raiseInvalidFormat("closing \"'\" expected")
    else:
      if toAdd: emitChar(p, x, f[i])
      inc i
  p.i = i

proc scanBranch(p: var FormatParser, a: openArray[string],
                x: var string, choice: int) =
  var i = p.i
  var f = p.f
  var c = 0
  var elsePart = i
  var toAdd = choice == 0
  while true:
    case f[i]
    of ']': break
    of '|':
      inc i
      elsePart = i
      inc c
      if toAdd: break
      toAdd = choice == c
    of '\'':
      call: scanQuote(p, x, toAdd)
    of '\0': raiseInvalidFormat("closing ']' expected")
    else:
      if toAdd:
        if f[i] == '$':
          inc i
          call: scanDollar(p, a, x)
        else:
          emitChar(p, x, f[i])
          inc i
      else:
        inc i
  if not toAdd and choice >= 0:
    # evaluate 'else' part:
    var last = i
    i = elsePart
    while true:
      case f[i]
      of '|', ']': break
      of '\'':
        call: scanQuote(p, x, true)
      of '$':
        inc i
        call: scanDollar(p, a, x)
      else:
        emitChar(p, x, f[i])
        inc i
    i = last
  p.i = i+1

proc scanSlice(p: var FormatParser, a: openarray[string]): tuple[x, y: int] =
  var slice = false
  var i = p.i
  var f = p.f

  if f[i] == '{': inc i
  else: raiseInvalidFormat("'{' expected")
  if f[i] == '.' and f[i+1] == '.':
    inc i, 2
    slice = true
  else:
    call: result.x = getFormatArg(p, a)
    if f[i] == '.' and f[i+1] == '.':
      inc i, 2
      slice = true
  if slice:
    if f[i] != '}':
      call: result.y = getFormatArg(p, a)
    else:
      result.y = high(a)
  else:
    result.y = result.x
  if f[i] != '}': raiseInvalidFormat("'}' expected")
  inc i
  p.i = i

proc scanDollar(p: var FormatParser, a: openarray[string], s: var string) =
  var i = p.i
  var f = p.f
  case f[i]
  of '$':
    emitChar p, s, '$'
    inc i
  of '*':
    for j in 0..a.high: emitStr p, s, a[j]
    inc i
  of '{':
    call:
      let (x, y) = scanSlice(p, a)
    for j in x..y: emitStr p, s, a[j]
  of '[':
    inc i
    var start = i
    call: scanBranch(p, a, s, -1)
    var x: int
    if f[i] == '{':
      inc i
      call: x = getFormatArg(p, a)
      if f[i] != '}': raiseInvalidFormat("'}' expected")
      inc i
    else:
      call: x = getFormatArg(p, a)
    var last = i
    let choice = parseInt(a[x])
    i = start
    call: scanBranch(p, a, s, choice)
    i = last
  of '\'':
    var sep = ""
    callNoLineLenTracking: scanQuote(p, sep, true)
    if f[i] == '~':
      # $' '~{1..3}
      # insert space followed by 1..3 if not empty
      inc i
      call:
        let (x, y) = scanSlice(p, a)
      var L = 0
      for j in x..y: inc L, a[j].len
      if L > 0:
        emitStrLinear p, s, sep
        for j in x..y: emitStr p, s, a[j]
    else:
      block StringJoin:
        block OptionalLineLengthSpecifier:
          var maxLen = 0
          case f[i]
          of '0'..'9':
            while f[i] in Digits:
              maxLen = maxLen * 10 + ord(f[i]) - ord('0')
              inc i
          of '$':
            # do not skip the '$' here for `getFormatArg`!
            call:
              maxLen = getFormatArg(p, a)
          else: break OptionalLineLengthSpecifier
          var indent = ""
          case f[i]
          of 'i':
            inc i
            callNoLineLenTracking: scanQuote(p, indent, true)

            call:
              let (x, y) = scanSlice(p, a)
            if maxLen < 1: emitStrLinear(p, s, indent)
            var items = 1
            emitStr p, s, a[x]
            for j in x+1..y:
              emitStr p, s, sep
              if items >= maxLen:
                emitStrLinear p, s, indent
                items = 0
              emitStr p, s, a[j]
              inc items
          of 'c':
            inc i
            callNoLineLenTracking: scanQuote(p, indent, true)

            call:
              let (x, y) = scanSlice(p, a)
            if p.lineLen + a[x].len > maxLen: emitStrLinear(p, s, indent)
            emitStr p, s, a[x]
            for j in x+1..y:
              emitStr p, s, sep
              if p.lineLen + a[j].len > maxLen: emitStrLinear(p, s, indent)
              emitStr p, s, a[j]

          else: raiseInvalidFormat("unit 'c' (chars) or 'i' (items) expected")
          break StringJoin

        call:
          let (x, y) = scanSlice(p, a)
        emitStr p, s, a[x]
        for j in x+1..y:
          emitStr p, s, sep
          emitStr p, s, a[j]
  else:
    call:
      var x = getFormatArg(p, a)
    emitStr p, s, a[x]
  p.i = i


type
  Subex* = distinct string ## string that contains a substitution expression

{.deprecated: [TSubex: Subex].}

proc subex*(s: string): Subex =
  ## constructs a *substitution expression* from `s`. Currently this performs
  ## no syntax checking but this may change in later versions.
  result = Subex(s)

proc addf*(s: var string, formatstr: Subex, a: varargs[string, `$`]) {.
           noSideEffect, rtl, extern: "nfrmtAddf".} =
  ## The same as ``add(s, formatstr % a)``, but more efficient.
  var p: FormatParser
  p.f = formatstr.string
  var i = 0
  while i < len(formatstr.string):
    if p.f[i] == '$':
      inc i
      call: scanDollar(p, a, s)
    else:
      emitChar(p, s, p.f[i])
      inc(i)

proc `%` *(formatstr: Subex, a: openarray[string]): string {.noSideEffect,
  rtl, extern: "nfrmtFormatOpenArray".} =
  ## The `substitution`:idx: operator performs string substitutions in
  ## `formatstr` and returns a modified `formatstr`. This is often called
  ## `string interpolation`:idx:.
  ##
  result = newStringOfCap(formatstr.string.len + a.len shl 4)
  addf(result, formatstr, a)

proc `%` *(formatstr: Subex, a: string): string {.noSideEffect,
  rtl, extern: "nfrmtFormatSingleElem".} =
  ## This is the same as ``formatstr % [a]``.
  result = newStringOfCap(formatstr.string.len + a.len)
  addf(result, formatstr, [a])

proc format*(formatstr: Subex, a: varargs[string, `$`]): string {.noSideEffect,
  rtl, extern: "nfrmtFormatVarargs".} =
  ## The `substitution`:idx: operator performs string substitutions in
  ## `formatstr` and returns a modified `formatstr`. This is often called
  ## `string interpolation`:idx:.
  ##
  result = newStringOfCap(formatstr.string.len + a.len shl 4)
  addf(result, formatstr, a)

{.pop.}

when isMainModule:
  from strutils import replace

  proc `%`(formatstr: string, a: openarray[string]): string =
    result = newStringOfCap(formatstr.len + a.len shl 4)
    addf(result, formatstr.Subex, a)

  proc `%`(formatstr: string, a: string): string =
    result = newStringOfCap(formatstr.len + a.len)
    addf(result, formatstr.Subex, [a])


  doAssert "$# $3 $# $#" % ["a", "b", "c"] == "a c b c"
  doAssert "$animal eats $food." % ["animal", "The cat", "food", "fish"] ==
           "The cat eats fish."


  doAssert "$[abc|def]# $3 $# $#" % ["17", "b", "c"] == "def c b c"
  doAssert "$[abc|def]# $3 $# $#" % ["1", "b", "c"] == "def c b c"
  doAssert "$[abc|def]# $3 $# $#" % ["0", "b", "c"] == "abc c b c"
  doAssert "$[abc|def|]# $3 $# $#" % ["17", "b", "c"] == " c b c"

  doAssert "$[abc|def|]# $3 $# $#" % ["-9", "b", "c"] == " c b c"
  doAssert "$1($', '{2..})" % ["f", "a", "b"] == "f(a, b)"

  doAssert "$[$1($', '{2..})|''''|fg'$3']1" % ["7", "a", "b"] == "fg$3"

  doAssert "$[$#($', '{#..})|''''|$3]1" % ["0", "a", "b"] == "0(a, b)"
  doAssert "$' '~{..}" % "" == ""
  doAssert "$' '~{..}" % "P0" == " P0"
  doAssert "${$1}" % "1" == "1"
  doAssert "${$$-1} $$1" % "1" == "1 $1"

  doAssert(("$#($', '10c'\n    '{#..})" % ["doAssert", "longishA", "longish"]).replace(" \n", "\n") ==
           """doAssert(
    longishA,
    longish)""")

  doAssert(("type MyEnum* = enum\n  $', '2i'\n  '{..}" % ["fieldA",
    "fieldB", "FiledClkad", "fieldD", "fieldE", "longishFieldName"]).replace(" \n", "\n") ==
    strutils.unindent("""
      type MyEnum* = enum
        fieldA, fieldB,
        FiledClkad, fieldD,
        fieldE, longishFieldName""", 6))

  doAssert subex"$1($', '{2..})" % ["f", "a", "b", "c"] == "f(a, b, c)"

  doAssert subex"$1 $[files|file|files]{1} copied" % ["1"] == "1 file copied"

  doAssert subex"$['''|'|''''|']']#" % "0" == "'|"

  doAssert((subex("type\n  Enum = enum\n    $', '40c'\n    '{..}") % [
    "fieldNameA", "fieldNameB", "fieldNameC", "fieldNameD"]).replace(" \n", "\n") ==
    strutils.unindent("""
      type
        Enum = enum
          fieldNameA, fieldNameB, fieldNameC,
          fieldNameD""", 6))
