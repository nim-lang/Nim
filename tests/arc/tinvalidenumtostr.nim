discard """
  output: '''
invalid data
'''
"""

# issue #24875

type
  MyEnum = enum
    One = 1

var x = cast[MyEnum](0)
echo x
