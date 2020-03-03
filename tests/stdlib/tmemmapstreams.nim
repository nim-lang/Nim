discard """
output: '''
Created size: 10
Position after writing: 5
Position after writing one char: 6
Peeked data: Hello
Position after peeking: 0
Readed data: Hello!
Position after reading line: 7
Position after setting position: 6
Readed line: Hello!
Position after reading line: 7'''
"""
import os, streams, memfiles
const
  fn = "test.mmapstream"
var
  mms: MemMapFileStream

if fileExists(fn): removeFile(fn)

# Create a new memory mapped file, data all zeros
mms = newMemMapFileStream(fn, mode = fmReadWrite, fileSize = 10)
mms.close()
if fileExists(fn): echo "Created size: ", getFileSize(fn)

# write, flush, peek, read
mms = newMemMapFileStream(fn, mode = fmReadWrite)
let s = "Hello"

mms.write(s)
mms.flush
echo "Position after writing: ", mms.getPosition()
mms.write('!')
mms.flush
echo "Position after writing one char: ", mms.getPosition()
mms.close()

mms = newMemMapFileStream(fn, mode = fmRead)
echo "Peeked data: ", mms.peekStr(s.len)
echo "Position after peeking: ", mms.getPosition()
echo "Readed data: ", mms.readLine
echo "Position after reading line: ", mms.getPosition()
mms.setPosition(mms.getPosition() - 1)
echo "Position after setting position: ", mms.getPosition()

mms.setPosition(0)
echo "Readed line: ", mms.readLine
echo "Position after reading line: ", mms.getPosition()

mms.close()

if fileExists(fn): removeFile(fn)
