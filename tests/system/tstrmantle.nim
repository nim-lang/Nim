var res = newStringOfCap(24)

for i in 0 .. 9:
  res.addInt int64(i)

doAssert res == "0123456789"

res.setLen(0)

for i in -9 .. 0:
  res.addInt int64(i)

doAssert res == "-9-8-7-6-5-4-3-2-10"

res.setLen(0)
res.addInt high(int64)
doAssert res == "9223372036854775807"

res.setLen(0)
res.addInt low(int64)
doAssert res == "-9223372036854775808"

res.setLen(0)
res.addInt high(int32)
doAssert res == "2147483647"

res.setLen(0)
res.addInt low(int32)
doAssert res == "-2147483648"

res.setLen(0)
res.addInt high(int16)
doAssert res == "32767"

res.setLen(0)
res.addInt low(int16)
doAssert res == "-32768"


res.setLen(0)
res.addInt high(int8)
doAssert res == "127"

res.setLen(0)
res.addInt low(int8)
doAssert res == "-128"
