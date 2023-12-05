discard """
  nimout: '''
tinttouint.nim(9, 17) Error: illegal conversion from '-1' to '[0'u..18446744073709551615'u]'
'''
"""

static:
  let a = -1
  discard uint64(a)
