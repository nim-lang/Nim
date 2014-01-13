discard """
  output: '''9
1
2
3
'''
"""

# Test the new overloading rules for iterators:

# test that iterator 'p' is preferred:
proc p(): seq[int] = @[1, 2, 3]
iterator p(): int = yield 9

for x in p(): echo x

# test that 'q' works in this position:
proc q(): seq[int] = @[1, 2, 3]

for x in q(): echo x

