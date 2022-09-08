discard """
  errormsg: "Multiple varargs parameters are disallowed"
"""

proc test(a: varargs[int], b: varargs[int]) = doAssert a != b