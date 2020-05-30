discard """
  input: "Arne"
  output: '''
Hello! What is your name?
Nice name: Arne
fs is: nil

threw exception
'''
  nimout: '''
I
AM
GROOT
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

  static:
    var s = newStringStream("I\nAM\nGROOT")
    for line in s.lines:
      echo line
    s.close
