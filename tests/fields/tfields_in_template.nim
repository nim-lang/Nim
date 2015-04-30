discard """
  output: '''n
n'''
"""

# bug #1902
# This works.
for name, value in (n: "v").fieldPairs:
  echo name

# This doesn't compile - "expression 'name' has no type (or is ambiguous)".
template wrapper: stmt =
  for name, value in (n: "v").fieldPairs:
    echo name
wrapper()
