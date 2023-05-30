#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[

Syntax taken from strscans.nim:

=================   ========================================================
``$$``              Matches a single dollar sign.
``$*``              Matches until the token following the ``$*`` was found.
                    The match is allowed to be of 0 length.
``$+``              Matches until the token following the ``$+`` was found.
                    The match must consist of at least one char.
``$s``              Skips optional whitespace.
=================   ========================================================

]##

import tables
from strutils import continuesWith, Whitespace

type
  Opcode = enum
    MatchVerbatim # needs verbatim match
    Capture0Until
    Capture1Until
    Capture0UntilEnd
    Capture1UntilEnd
    SkipWhitespace

  Instr = object
    opc: Opcode
    arg1: uint8
    arg2: uint16

  Pattern* = object
    code: seq[Instr]
    usedMatches: int
    error: string

# A rewrite rule looks like:
#
# foo$*bar -> https://gitlab.cross.de/$1

proc compile*(pattern: string; strings: var seq[string]): Pattern =
  proc parseSuffix(s: string; start: int): int =
    result = start
    while result < s.len and s[result] != '$':
      inc result

  result = Pattern(code: @[], usedMatches: 0, error: "")
  var p = 0
  while p < pattern.len:
    if pattern[p] == '$' and p+1 < pattern.len:
      case pattern[p+1]
      of '$':
        if result.code.len > 0 and result.code[^1].opc in {
              MatchVerbatim, Capture0Until, Capture1Until, Capture0UntilEnd, Capture1UntilEnd}:
          # merge with previous opcode
          let key = strings[result.code[^1].arg2] & "$"
          var idx = find(strings, key)
          if idx < 0:
            idx = strings.len
            strings.add key
          result.code[^1].arg2 = uint16(idx)
        else:
          var idx = find(strings, "$")
          if idx < 0:
            idx = strings.len
            strings.add "$"
          result.code.add Instr(opc: MatchVerbatim,
                                arg1: uint8(0), arg2: uint16(idx))
        inc p, 2
      of '+', '*':
        let isPlus = pattern[p+1] == '+'

        let pEnd = parseSuffix(pattern, p+2)
        let suffix = pattern.substr(p+2, pEnd-1)
        p = pEnd
        if suffix.len == 0:
          result.code.add Instr(opc: if isPlus: Capture1UntilEnd else: Capture0UntilEnd,
                                arg1: uint8(result.usedMatches), arg2: uint16(0))
        else:
          var idx = find(strings, suffix)
          if idx < 0:
            idx = strings.len
            strings.add suffix
          result.code.add Instr(opc: if isPlus: Capture1Until else: Capture0Until,
                                arg1: uint8(result.usedMatches), arg2: uint16(idx))
        inc result.usedMatches

      of 's':
        result.code.add Instr(opc: SkipWhitespace)
        inc p, 2
      else:
        result.error = "unknown syntax '$" & pattern[p+1] & "'"
        break
    elif pattern[p] == '$':
      result.error = "unescaped '$'"
      break
    else:
      let pEnd = parseSuffix(pattern, p)
      let suffix = pattern.substr(p, pEnd-1)
      var idx = find(strings, suffix)
      if idx < 0:
        idx = strings.len
        strings.add suffix
      result.code.add Instr(opc: MatchVerbatim,
                            arg1: uint8(0), arg2: uint16(idx))
      p = pEnd

type
  MatchObj = object
    m: int
    a: array[20, (int, int)]

proc matches(s: Pattern; strings: seq[string]; input: string): MatchObj =
  template failed =
    result.m = -1
    return result

  var i = 0
  for instr in s.code:
    case instr.opc
    of MatchVerbatim:
      if continuesWith(input, strings[instr.arg2], i):
        inc i, strings[instr.arg2].len
      else:
        failed()
    of Capture0Until, Capture1Until:
      block searchLoop:
        let start = i
        while i < input.len:
          if continuesWith(input, strings[instr.arg2], i):
            if instr.opc == Capture1Until and i == start:
              failed()
            result.a[result.m] = (start, i-1)
            inc result.m
            inc i, strings[instr.arg2].len
            break searchLoop
          inc i
        failed()

    of Capture0UntilEnd, Capture1UntilEnd:
      if instr.opc == Capture1UntilEnd and i >= input.len:
        failed()
      result.a[result.m] = (i, input.len-1)
      inc result.m
      i = input.len
    of SkipWhitespace:
      while i < input.len and input[i] in Whitespace: inc i
  if i < input.len:
    # still unmatched stuff was left:
    failed()

proc translate(m: MatchObj; outputPattern, input: string): string =
  result = newStringOfCap(outputPattern.len)
  var i = 0
  var patternCount = 0
  while i < outputPattern.len:
    if i+1 < outputPattern.len and outputPattern[i] == '$':
      if outputPattern[i+1] == '#':
        inc i, 2
        if patternCount < m.a.len:
          let (a, b) = m.a[patternCount]
          for j in a..b: result.add input[j]
        inc patternCount
      elif outputPattern[i+1] in {'1'..'9'}:
        var n = ord(outputPattern[i+1]) - ord('0')
        inc i, 2
        while i < outputPattern.len and outputPattern[i] in {'0'..'9'}:
          n = n * 10 + (ord(outputPattern[i]) - ord('0'))
          inc i
        patternCount = n
        if n-1 < m.a.len:
          let (a, b) = m.a[n-1]
          for j in a..b: result.add input[j]
      else:
        # just ignore the wrong pattern:
        inc i
    else:
      result.add outputPattern[i]
      inc i

proc replace*(s: Pattern; outputPattern, input: string): string =
  var strings: seq[string] = @[]
  let m = s.matches(strings, input)
  if m.m < 0:
    result = ""
  else:
    result = translate(m, outputPattern, input)


type
  Patterns* = object
    s: seq[(Pattern, string)]
    t: Table[string, string]
    strings: seq[string]

proc initPatterns*(): Patterns =
  Patterns(s: @[], t: initTable[string, string](), strings: @[])

proc addPattern*(p: var Patterns; inputPattern, outputPattern: string): string =
  if '$' notin inputPattern and '$' notin outputPattern:
    p.t[inputPattern] = outputPattern
    result = ""
  else:
    let code = compile(inputPattern, p.strings)
    if code.error.len > 0:
      result = code.error
    else:
      p.s.add (code, outputPattern)
      result = ""

proc substitute*(p: Patterns; input: string): string =
  result = p.t.getOrDefault(input)
  if result.len == 0:
    for i in 0..<p.s.len:
      let m = p.s[i][0].matches(p.strings, input)
      if m.m >= 0:
        return translate(m, p.s[i][1], input)

proc replacePattern*(inputPattern, outputPattern, input: string): string =
  var strings: seq[string] = @[]
  let code = compile(inputPattern, strings)
  result = replace(code, outputPattern, input)

when isMainModule:
  # foo$*bar -> https://gitlab.cross.de/$1
  const realInput = "$fooXXbar$z00end"
  var strings: seq[string] = @[]
  let code = compile("$$foo$*bar$$$*z00$*", strings)
  echo code

  let m = code.matches(strings, realInput)
  echo m.m

  echo translate(m, "$1--$#-$#-", realInput)

  echo translate(m, "https://gitlab.cross.de/$1", realInput)

