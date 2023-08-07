discard """
  nimout: '''
touinttoint.nim(9, 16) Error: illegal conversion from '18446744073709551615'u' to '[-9223372036854775808..9223372036854775807]'
'''
"""

static:
  let a = uint64.high
  discard int64(a)
