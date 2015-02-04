# test the new unsigned operations:

import
  strutils

var
  x, y: int

x = 1
y = high(int)

writeln(stdout, $ ( x +% y ) )
