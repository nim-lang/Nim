discard """
nimout: '''
StmtList
  UIntLit 18446744073709551615
  IntLit -1'''
"""

import macros

dumpTree:
  0xFFFFFFFF_FFFFFFFF'u
  0xFFFFFFFF_FFFFFFFF

