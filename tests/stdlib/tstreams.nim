discard """
  input: "Arne"
  output: '''
Hello! What is your name?
Nice name: Arne
fs is: nil
threw exception
_heh_
'''
  nimout: '''
I
AM
GROOT
'''
"""


import streams


block tstreams:
  var outp = newFileStream(stdout)
  var inp = newFileStream(stdin)
  writeLine(outp, "Hello! What is your name?")
  var line = readLine(inp)
  writeLine(outp, "Nice name: " & line)


block tstreams2:
  var
    fs = newFileStream("amissingfile.txt")
    line = ""
  echo "fs is: ",repr(fs)
  if not isNil(fs):
    while fs.readLine(line):
      echo line
    fs.close()


block tstreams3:
  try:
    var fs = openFileStream("shouldneverexist.txt")
  except IoError:
    echo "threw exception"

  static:
    var s = newStringStream("I\nAM\nGROOT")
    for line in s.lines:
      echo line
    s.close

# bug #12410

var a = newStringStream "hehohihahuhyh"
a.readDataStrImpl = nil

var buffer = "_ooo_"

doAssert a.readDataStr(buffer, 1..3) == 3

echo buffer


block:
  var ss = newStringStream("The quick brown fox jumped over the lazy dog.\nThe lazy dog ran")
  doAssert(ss.getPosition == 0)
  doAssert(ss.peekStr(5) == "The q")
  doAssert(ss.getPosition == 0) # haven't moved
  doAssert(ss.readStr(5) == "The q")
  doAssert(ss.getPosition == 5) # did move
  doAssert(ss.peekLine() == "uick brown fox jumped over the lazy dog.")
  doAssert(ss.getPosition == 5) # haven't moved
  var str = newString(100)
  doAssert(ss.peekLine(str))
  doAssert(str == "uick brown fox jumped over the lazy dog.")
  doAssert(ss.getPosition == 5) # haven't moved
