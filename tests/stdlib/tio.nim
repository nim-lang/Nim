discard """
  output: '''9
b = true
123456789
Second readLine raised an exception
123456789
1
2aaaaaaaa
3bbbbbbb
'''
"""
# bug #5349
import os

# test the file-IO

const fn = "file9char.txt"

writeFile(fn, "123456789")

var f = open(fn)
echo getFileSize(f)

var line = newString(10)
try:
  let b = readLine(f, line)
  echo "b = ", b
except:
  echo "First readLine raised an exception"

echo line

try:
  line = readLine(f)
  let b = readLine(f, line)
  echo "b = ", b
except:
  echo "Second readLine raised an exception"

echo line
f.close()

removeFile(fn)

# bug #8961
writeFile("test.txt", "1\C\L2aaaaaaaa\C\L3bbbbbbb")

for line in lines("test.txt"):
  echo line
