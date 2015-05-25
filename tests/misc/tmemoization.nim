discard """
  msg:    "test 1\Ntest 2\Ntest 3"
  output: "TEST 1\NTEST 2\NTEST 3"
"""

import strutils

proc foo(s: static[string]): string =
  static: echo s

  const R = s.toUpper
  return R

echo foo("test 1")
echo foo("test 2")
echo foo("test " & $3)

