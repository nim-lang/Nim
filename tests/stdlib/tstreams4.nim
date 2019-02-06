# bug #9026
import streams

iterator readFile*(stream: Stream): int =
  var num = 0
  var line = ""
  while stream.readLine(line):
    num += 1
    yield line.len

iterator readFile*(s: string): int =
  for x in readFile(newStringStream(s)):
    yield x

let
  filenames = ["bin.txt", "str.txt"]
  expected = [14334, 20773]

for i, filename in filenames:
  var lines = 0
  for x in readFile(newFileStream(filename)):
    lines += 1
  doAssert lines == expected[i]
