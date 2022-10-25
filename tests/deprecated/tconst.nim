discard """
  nimout: '''
tconst.nim(8, 9) Warning: abcd; foo is deprecated [Deprecated]
'''
"""

const foo* {.deprecated: "abcd".} = 42
discard foo
