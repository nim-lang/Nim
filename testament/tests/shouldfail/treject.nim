discard """
  action: "reject"
"""

# Because we set action="reject", we expect this line not to compile. But the
# line does compile, therefore the test fails.
assert true
