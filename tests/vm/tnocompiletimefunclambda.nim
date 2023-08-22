discard """
  errormsg: "request to generate code for .compileTime proc: :anonymous"
"""

let a = func(a: varargs[int]) {.compileTime, closure.} =
  discard a[0]