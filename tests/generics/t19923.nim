discard """
action: compile
"""

# bug #19923

type Test[S: static[Natural]] = object

proc run(self: Test, idx: 0..(self.S * 8)) = discard
#       This causes segfault ^^^^^^^^^^^^
proc run(self: Test, a: array[self.S * 8, int]) = discard
#                And this too ^^^^^^^^^^
