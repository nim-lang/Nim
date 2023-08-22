discard """
  nimout:    "test 1\ntest 2\ntest 3"
  output: "TEST 1\nTEST 2\nTEST 3"
"""

import strutils

proc foo(s: static[string]): string =
  static: echo s

  const R = s.toUpperAscii
  return R

echo foo("test 1")
echo foo("test 2")
echo foo("test " & $3)

