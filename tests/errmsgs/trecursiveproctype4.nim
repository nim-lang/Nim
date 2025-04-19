discard """
  errormsg: "illegal recursion in type 'BB'"
  line: 9
"""

# issue #23885

type
  EventHandler = proc(target: BB)
  BB = (EventHandler,)
