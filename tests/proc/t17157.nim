discard """
  errormsg: "'untyped' is only allowed in templates and macros or magic procs"
"""

template something(op: proc (v: untyped): void): void =
  discard
