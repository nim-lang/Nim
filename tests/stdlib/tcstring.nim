discard """
  targets: "c cpp js"
"""


block: # bug #13859
  let str = "abc".cstring
  doAssert len(str).int8 == 3
  doAssert len(str).int16 == 3
  doAssert len(str).int32 == 3
  var str2 = "cde".cstring
  doAssert len(str2).int8 == 3
  doAssert len(str2).int16 == 3
  doAssert len(str2).int32 == 3

  const str3 = "abc".cstring
  doAssert len(str3).int32 == 3
  doAssert len("abc".cstring).int16 == 3
  doAssert len("abc".cstring).float32 == 3.0
