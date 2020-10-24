discard """
action: "reject"
"""

# Because we set action="reject", we expect this line to not compile. But the
# line does compile, therefore the test fails.
assert true