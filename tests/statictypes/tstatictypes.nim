discard """
nimout: '''
staticAlialProc instantiated with 4
staticAlialProc instantiated with 6
'''
"""

type
  StaticTypeAlias = static[int]

proc staticAliasProc(s: StaticTypeAlias) =
  static: echo "staticAlialProc instantiated with ", s + 1

staticAliasProc 1+2
staticAliasProc 3
staticAliasProc 5

