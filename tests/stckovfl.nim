# To test stack overflow message

import std/assertions

proc over(a: int): int =
  if a >= 10:
    assert false
    return
  result = over(a+1)+5

Echo($over(0))

