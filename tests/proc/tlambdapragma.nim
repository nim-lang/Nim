discard """
  errmsg: "invalid pragma: exportc"
"""

let _ = proc () {.exportc.} =
  # this would previously cause a codegen error
  discard