import endians

proc main() =
  var
    a8: int8 = 123
    a16: int16 = 0x1234
    a32: int32 = 0x12345678
    a64: int64 = 0x123456789abcde1f
    l8 = a8.getLittleEndian()
    l16 = a16.getLittleEndian()
    l32 = a32.getLittleEndian
    l64 = a64.getLittleEndian
    b8 = a8.getBigEndian
    b16 = a16.getBigEndian
    b32 = a32.getBigEndian
    b64 = a64.getBigEndian

  when system.cpuEndian == bigEndian:
    doAssert l8 == 123
    doAssert l16 == 0x3412
    doAssert l32 == 0x78563412
    doAssert l64 == 0x1fdebc9a78563412
    doAssert b8 == 123
    doAssert b16 == 0x1234
    doAssert b32 == 0x12345678
    doAssert b64 == 0x123456789abcde1f
  else:
    doAssert l8 == 123
    doAssert l16 == 0x1234
    doAssert l32 == 0x12345678
    doAssert l64 == 0x123456789abcde1f
    doAssert b8 == 123
    doAssert b16 == 0x3412
    doAssert b32 == 0x78563412
    doAssert b64 == 0x1fdebc9a78563412

main()
