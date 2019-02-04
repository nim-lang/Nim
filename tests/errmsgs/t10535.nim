discard """
  errormsg: "cannot evaluate {.compileTime.} proc 'fun' at runtime"
  line: 11
"""

proc fun(){.compileTime.} =
  echo "step2"

static: echo "step1"

fun() # user error: should've been: `static: fun()`

static: echo "step3 (with side effects) that expects step2 to run before"
