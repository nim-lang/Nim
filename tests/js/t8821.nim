
proc isInt32(i: int): bool =
  case i 
  of 1 .. 70000:
    return true
  else:
    return false

doAssert isInt32(1) == true