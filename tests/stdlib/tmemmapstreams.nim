discard """
  file: "tmemmapstreams.nim"
  output: '''Created size: 10
Position after writing: 5
Peeked data: Hello
Position after peeking: 0
Readed data: Hello
Position after reading line: 6
Position after setting position: 5
Position after writing one char: 6
New readed line: Hello!
Position after reading line: 7'''
"""
import os, streams
var
  mms1, mms2: MemMapFileStream
  fn = "test.mmapstream"

if fileExists(fn): removeFile(fn)

# Create a new memory mapped file, data all zeros
mms1 = newMemMapFileStream(fn, mode = fmReadWrite, fileSize = 10)
mms1.close()
if fileExists(fn): echo "Created size: ", getFileSize(fn)

# write, flush, peek, read
mms1 = newMemMapFileStream(fn, mode = fmReadWrite, fileSize = 10)
mms2 = newMemMapFileStream(fn, mode = fmRead)

let s = "Hello"

mms1.write(s)
mms1.flush
echo "Position after writing: ", mms1.getPosition()
echo "Peeked data: ", mms2.peekStr(s.len)
echo "Position after peeking: ", mms2.getPosition()
echo "Readed data: ", mms2.readLine
echo "Position after reading line: ", mms2.getPosition()
mms1.setPosition(mms2.getPosition() - 1)
echo "Position after setting position: ", mms1.getPosition()
mms1.write('!')
mms1.flush
echo "Position after writing one char: ", mms1.getPosition()
mms2.setPosition(0)
echo "New readed line: ", mms2.readLine
echo "Position after reading line: ", mms2.getPosition()

mms1.close()
mms2.close()

if fileExists(fn): removeFile(fn)
