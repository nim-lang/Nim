discard """
  nimout: '''
Infix
  Ident "from"
  Ident "a"
  Ident "b"
'''
"""

from macros import dumpTree

dumpTree(a from b)