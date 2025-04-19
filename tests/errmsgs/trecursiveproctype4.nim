discard """
  errormsg: "illegal recursion in type 'BB'"
  line: 10
"""

# issue #23885

type
  EventHandler = proc(target: BB)
  BB = (EventHandler,)
