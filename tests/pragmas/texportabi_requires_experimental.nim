discard """
  errormsg: "enable the experimental 'abi' feature to use {.exportabi.}"
  line: 6
"""

proc exported() {.exportabi.} =
  discard
