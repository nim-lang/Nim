discard """
action: compile
"""
proc foo[T](t: T) = discard

proc bar[T](t: T) =
  # Fails here
  foo[void](t)

bar[void]()