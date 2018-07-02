discard """
  file: "tstreams4.nim"
  output: '''0
1'''
"""
import streams, os
const
  fn = "test.stream.size"
var
  fs = newFileStream(fn, fmWrite)

echo fs.size
fs.write('1')
echo fs.size
fs.close

if fileExists(fn): removeFile(fn)

