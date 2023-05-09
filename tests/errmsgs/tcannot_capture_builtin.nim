discard """
errormsg: "'+' is a built-in and cannot be used as a first-class procedure"
line: 8
"""

# bug #2050

let v: proc (a, b: int): int = `+`
