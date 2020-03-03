discard """
  errormsg: "identifier expected, but got 'keyword when'"
"""

# bug #2123
type num = enum
    NUM_NONE = 0
    NUM_ALL = 1
    when defined(macosx): NUM_OSX = 10 # only this differs for real
    NUM_XTRA = 20

