# Test operator overloading

import
  io

proc % (a, b: int): int =
  return a mod b

var x, y: int
x = 15
y = 6
write(stdout, x % y)
#OUT 3
