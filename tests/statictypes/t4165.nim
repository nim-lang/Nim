discard """
  errormsg: "static parameters cannot be accessed at runtime"
"""

proc printStr(s: static[string]) =
  {.emit: "puts(`s`->data);" .}
printStr("hello static")
