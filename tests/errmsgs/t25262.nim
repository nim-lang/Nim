discard """
  errormsg: '''type mismatch: got <>'''
"""

proc v[T: typedesc]() = discard
v[0]()