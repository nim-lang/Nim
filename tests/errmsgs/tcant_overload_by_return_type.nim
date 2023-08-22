discard """
errormsg: "overloaded 'x' leads to ambiguous calls"
line: 9
"""

# bug #6393

proc x(): int = 7
proc x(): string = "strange"
