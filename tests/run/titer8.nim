discard """
  output: '''tada
1
2
3
ta da1
2
3'''
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

iterator count3(): int {.closure.} =
  yield 1
  yield 2
  yield 3

for word, isSep in tokenize2("ta da", whiteSpace):
  if not isSep:
    stdout.write(word)
echo ""

proc inProc() =
  for c in count3():
    echo c
  
  for word, isSep in tokenize2("ta da", whiteSpace):
    stdout.write(word)

  for c in count3():
    echo c


inProc()

