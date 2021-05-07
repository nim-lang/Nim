discard """
  cmd: "nim c --styleCheck:error --styleCheck:usages $file"
  errormsg: "'BAD_STYLE' should be: 'BADSTYLE'"
  line: 20
"""

import strutils

proc BADSTYLE(c: char) = discard

proc toSnakeCase(s: string): string =
  result = newStringOfCap(s.len + 3)
  for i in 0..<s.len:
    if s[i] in {'A'..'Z'}:
      if i > 0 and s[i-1] in {'a'..'z'}:
        result.add '_'
      result.add toLowerAscii(s[i])
    else:
      result.add s[i]
    BAD_STYLE(s[i])

echo toSnakeCase("fooBarBaz Yes")

