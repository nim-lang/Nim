discard """
  cmd: '''nim c --newruntime $file'''
  output: '''hi
ho
ha
1 1'''
"""

import allocators
include system / ansi_c

proc main =
  var s: seq[string] = @[]
  for i in 0..<80: s.add "foo"

main()

const
  test = @["hi", "ho", "ha"]

for t in test:
  echo t

type
  InterpolatedKind* = enum
    ikStr,                   ## ``str`` part of the interpolated string
    ikDollar,                ## escaped ``$`` part of the interpolated string
    ikVar,                   ## ``var`` part of the interpolated string
    ikExpr                   ## ``expr`` part of the interpolated string

iterator interpolatedFragments*(s: string): tuple[kind: InterpolatedKind,
                                                  value: string] =
  var i = 0
  var kind: InterpolatedKind
  while true:
    var j = i
    if j < s.len and s[j] == '$':
      if j+1 < s.len and s[j+1] == '{':
        inc j, 2
        var nesting = 0
        block curlies:
          while j < s.len:
            case s[j]
            of '{': inc nesting
            of '}':
              if nesting == 0:
                inc j
                break curlies
              dec nesting
            else: discard
            inc j
          raise newException(ValueError,
            "Expected closing '}': " & substr(s, i, s.high))
        inc i, 2 # skip ${
        kind = ikExpr
      elif j+1 < s.len and s[j+1] in {'A'..'Z', 'a'..'z', '_'}:
        inc j, 2
        while j < s.len and s[j] in {'A'..'Z', 'a'..'z', '0'..'9', '_'}: inc(j)
        inc i # skip $
        kind = ikVar
      elif j+1 < s.len and s[j+1] == '$':
        inc j, 2
        inc i # skip $
        kind = ikDollar
      else:
        raise newException(ValueError,
          "Unable to parse a varible name at " & substr(s, i, s.high))
    else:
      while j < s.len and s[j] != '$': inc j
      kind = ikStr
    if j > i:
      # do not copy the trailing } for ikExpr:
      yield (kind, substr(s, i, j-1-ord(kind == ikExpr)))
    else:
      break
    i = j

when false:
  let input = "$test{}  $this is ${an{  example}}  "
  let expected = @[(ikVar, "test"), (ikStr, "{}  "), (ikVar, "this"),
                  (ikStr, " is "), (ikExpr, "an{  example}"), (ikStr, "  ")]
  var i = 0
  for s in interpolatedFragments(input):
    doAssert s == expected[i]
    inc i


#echo s
let (a, d) = allocCounters()
discard cprintf("%ld %ld\n", a, d)
