discard """
  errmsg: "cannot discard future, use asyncCheck instead"
"""

import async

proc foo {.async.} = discard

discard foo()
