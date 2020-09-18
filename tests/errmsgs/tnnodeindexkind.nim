discard """
  errormsg: "cannot set child of node kind: nnkStrLit"
  line: 7
"""
import macros
macro t(x: untyped): untyped =
  x[0] = newEmptyNode()
t("abc")
