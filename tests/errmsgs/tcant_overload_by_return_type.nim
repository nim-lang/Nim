discard """
errormsg: "overload 'tcant_overload_by_return_type.nim(8, 6)' with incompatible types leads to ambiguous calls"
line: 9
"""

# bug #6393

proc x(): int = 7
proc x(): string = "strange"
