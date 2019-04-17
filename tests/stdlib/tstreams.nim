discard """
input: "Arne"
output: '''
Hello! What is your name?
Nice name: Arne
fs is: nil

threw exception
'''
disabled: "windows"
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


block t11049:
  var strm = newStringStream("abcdefghijklm")
  assert strm.readBool()
  assert strm.readBool() == true
  assert strm.readBool() != false
  assert not (strm.readBool() != true)
  assert not (strm.readBool() == false)

  assert strm.peekBool()
  assert strm.peekBool() == true
  assert strm.peekBool() != false
  assert not (strm.peekBool() != true)
  assert not (strm.peekBool() == false)

  strm.close()
