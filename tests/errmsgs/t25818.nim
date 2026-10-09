discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "implementation of 't25818.hello()' expected"
"""

# bug #25818
proc hello():
  if not true:
    discard
