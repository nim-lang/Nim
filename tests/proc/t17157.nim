discard """
  errormsg: "'untyped' is only allowed in templates and macros or magic procs"
  disabled: true
"""

template something(op: proc (v: untyped): void): void =
  discard
