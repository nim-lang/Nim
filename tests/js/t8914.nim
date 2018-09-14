discard """
  output: '''
@[42]
@[24, 42]
'''
"""

var x = @[42,4242]
x.delete(1)
echo x
x.insert(24)
echo x
