discard """
  file: "tstreams.nim"
  output: "fs is: nil"
"""
import streams

block:
  # test read/peek procs
  var ss = newStringStream()
  write(ss, "123")
  assert ss.peekInt8() == 123'i8
  assert ss.peekInt16() == 123'i16
  assert ss.peekInt32() == 123'i32
  assert ss.peekInt64() == 123'i64
  assert ss.peekUInt8() == 123'u8
  assert ss.peekUInt16() == 123'u16
  assert ss.peekUInt32() == 123'u32
  assert ss.peekUInt64() == 123'u64
  assert ss.peekChar() == "1"
  assert ss.peekChar() == "123"
  ss.close()

block:
  var ss = newStringStream("The quick brown fox jumped over the lazy dog.\nThe lazy dog ran")
  write(ss, "123")
  assert ss.readAll() == "The quick brown fox jumped over the lazy dog.\nThe lazy dog ran123"
  ss.close()

block:
  var fs = newFileStream("amissingfile.txt")
  if isNil(fs):
    echo "fs is: nil"
