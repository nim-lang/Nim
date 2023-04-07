discard """
  errormsg: "the special identifier '_' is ignored in declarations and cannot be used"
"""

# issue #12094, #13804

template foo =
  let _ = 1
  echo _

foo()
