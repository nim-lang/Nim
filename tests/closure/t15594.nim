discard """
  errormsg: "The variable name cannot be `result`!"
"""

import sugar

proc begin(): int =
  capture result:
    echo 1+1
  result
