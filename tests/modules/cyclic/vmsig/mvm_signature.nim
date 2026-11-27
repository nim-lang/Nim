import ../tvm_signature {.cyclic.}

proc partnerHelper*(): int =
  result = 0
  for i in 0 ..< 3: result += helper2()
proc partnerUser*(x: array[partnerHelper(), int]): int = x.len
proc useGen*(): int =
  var z: array[6, int]
  gen("x", z)
