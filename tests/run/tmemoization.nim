discard """
  msg:    "test 1\ntest 2"
  output: "TEST 1\nTEST 2\nTEST 2"
"""

import strutils

proc foo(s: static[string]): string =
  static: echo s

  const R = s.toUpper
  return R
  
echo foo("test 1")
echo foo("test 2")
echo foo("test " & $2)

