discard """
  action: reject
  nimout: '''tusages.nim(22, 5) Error: 'BAD_STYLE' should be: 'BADSTYLE' [proc declared in tusages.nim(11, 6)]'''
  matrix: "--styleCheck:error --styleCheck:usages"
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
