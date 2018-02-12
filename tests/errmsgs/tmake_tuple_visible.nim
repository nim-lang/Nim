discard """
  errormsg: '''got <tuple of (type NimEdAppWindow, int)>'''
  line: 22
  nimout: '''got <tuple of (type NimEdAppWindow, int)>
but expected one of:
template xxx(tn: typedesc; i: int)'''
"""

type
  NimEdAppWindow = ptr NimEdAppWindowObj
  NimEdAppWindowObj = object
    i: int

template gDefineTypeExtended*(tn: typeDesc) =
  discard

gDefineTypeExtended (NimEdAppWindow)

template xxx*(tn: typeDesc, i: int) =
  discard

xxx (NimEdAppWindow, 0)
# bug #6776
