discard """
action: compile
"""

proc sort[T: uint8|char|byte](c: T) = discard
proc sort[T: bool](c: T) = discard

proc sorted[T](c: T): T = sort[T](c)

doAssert sorted(true) == false
