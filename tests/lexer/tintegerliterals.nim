# test the valid literals
doAssert 0b10 == 2
doAssert 0B10 == 2
doAssert 0x10 == 16
doAssert 0X10 == 16
doAssert 0o10 == 8
# the following is deprecated:
doAssert 0c10 == 8
doAssert 0C10 == 8
