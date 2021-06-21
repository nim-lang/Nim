discard """
  errormsg: '''Mixing types and values in tuples is not allowed.'''
  line: 19
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
