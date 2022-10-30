discard """
  errormsg: "undeclared identifier: '_'"
"""

# issue #12094, #13804

template foo =
  let _ = 1
  echo _

foo()
