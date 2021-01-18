discard """
output: '''
02
1
2
3
4
5
9
b = true
123456789
Second readLine raised an exception
123456789
1
2aaaaaaaa
3bbbbbbb
'''
"""

import terminal, colors, re, encodings, strutils, os


block t9394:
  let codeFg = ansiForegroundColorCode(colAliceBlue)
  let codeBg = ansiBackgroundColorCode(colAliceBlue)

  doAssert codeFg == "\27[38;2;240;248;255m"
  doAssert codeBg == "\27[48;2;240;248;255m"



block t5382:
  let regexp = re"^\/([0-9]{2})\.html$"
  var matches: array[1, string]
  discard "/02.html".find(regexp, matches)
  echo matches[0]



block tcount:
  # bug #1845, #2224
  var arr = [3,2,1,5,4]

  # bubble sort
  for i in low(arr)..high(arr):
    for j in i+1..high(arr): # Error: unhandled exception: value out of range: 5 [RangeDefect]
      if arr[i] > arr[j]:
        let tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp

  for i in low(arr)..high(arr):
    echo arr[i]

  # check this terminates:
  for x in countdown('\255', '\0'):
    discard



block t8468:
  when defined(windows):
    var utf16to8 = open(destEncoding = "utf-16", srcEncoding = "utf-8")
    var s = "some string"
    var c = utf16to8.convert(s)

    var z = newStringOfCap(s.len * 2)
    for x in s:
      z.add x
      z.add chr(0)

    doAssert z == c



block t5349:
  const fn = "file9char.txt"
  writeFile(fn, "123456789")

  var f = system.open(fn)
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

block t9456:
  var f: File
  f.close()
