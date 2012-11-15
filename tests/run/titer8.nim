discard """
  output: '''tada
ta da'''
"""
# Test first class iterator:

import strutils

iterator tokenize2(s: string, seps: set[char] = Whitespace): tuple[
  token: string, isSep: bool] {.closure.} =
  var i = 0
  while i < s.len:
    var j = i
    if s[j] in seps:
      while j < s.len and s[j] in seps: inc(j)
      if j > i:
        yield (substr(s, i, j-1), true)
    else:
      while j < s.len and s[j] notin seps: inc(j)
      if j > i:
        yield (substr(s, i, j-1), false)
    i = j

for word, isSep in tokenize2("ta da", whiteSpace):
  if not isSep:
    stdout.write(word)
echo ""

proc inProc() =
  for word, isSep in tokenize2("ta da", whiteSpace):
    stdout.write(word)

inProc()
