# bug #9891

import "."/tsamename2

# this works
callFun(fooBar2)

when true:
  # Error: attempting to call routine: 'processPattern'
  callFun(fooBar)

when true:
  # BUG: Error: internal error: expr(skModule); unknown symbol
  proc processPattern() = discard
  callFun(fooBar)
