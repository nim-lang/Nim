import std/compilesettings
from strutils import contains, `%`, count
import std/macros

proc checkEscapeImpl(actual: string, sub: seq[string]) =
  let num = actual.count("StackAddrEscapes")
  doAssert num == sub.len, $(sub.len, num) & "\n" & actual
  doAssert actual.count("Warning") == sub.len, "\n" & actual
  for ai in sub:
    doAssert ai in actual, "eexpected: " & ai & "\n" & actual

proc checkEscapeImpl(actual, sub: string) =
  checkEscapeImpl(actual, @[sub])

template checkEscape*(msg) =
  static: checkEscapeImpl(getCapturedMsgs(), msg)

template checkEscapeOK*() =
  static: checkEscapeImpl(getCapturedMsgs(), @[])

template ignoreEscape*(body) =
  {.push warning[StackAddrEscapes]: off.}
  body
  {.pop.}

macro viewConstraints*(n: proc): string =
  result = newLit viewConstraintsStr(n)
