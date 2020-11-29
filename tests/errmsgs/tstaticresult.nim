discard """
errormsg: '''
invalid type: 'static[int]' in this context: 'proc (x: int): static[int]' for proc
'''
"""

proc foo(x: int): static int =
  x + 123

echo foo(123)
