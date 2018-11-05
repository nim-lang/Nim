import streams


block tstreams:
  var outp = newFileStream(stdout)
  var inp = newFileStream(stdin)
  write(outp, "Hello! What is your name?")
  var line = readLine(inp)
  write(outp, "Nice name: " & line)


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
