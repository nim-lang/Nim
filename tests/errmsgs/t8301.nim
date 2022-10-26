discard """
  errormsg: "'void' cannot be assigned to 'result'"
"""

# bug #8301
proc foo_1():auto=
  void

when true:
  # Error: internal error: expr: var not init result_115006
  foo_p1()
