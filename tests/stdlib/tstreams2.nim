discard """
  test newFileStream opening a missing file returns nil
  file: "tstreams2.nim"
  output: 'fs is: nil'
"""
import streams
var
  fs = newFileStream("amissingfile.txt")
  line = ""
echo "fs is: ",repr(fs)
if not isNil(fs):
  while fs.readLine(line):
    echo line
  fs.close()
