discard """
  errormsg: "cannot infer the return type of 'p' from within a nested routine"
  line: 9
"""

# bug #18556
proc p(): auto =
  proc x() =
    result = "foo"
  x()

echo p()
