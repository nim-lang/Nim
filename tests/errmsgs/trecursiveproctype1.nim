discard """
  errormsg: "illegal recursion in type 'Behavior'"
  line: 10
"""

# issue #5631

type
  Behavior = proc(): Effect
  Effect   = proc(behavior: Behavior): Behavior
