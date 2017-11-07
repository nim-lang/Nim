discard """
  line: 9
  errormsg: "illegal capture 'x'"
"""

proc outer(arg: string) =
  var x = 0
  proc inner {.inline.} =
    echo "inner", x
  inner()

outer("abc")