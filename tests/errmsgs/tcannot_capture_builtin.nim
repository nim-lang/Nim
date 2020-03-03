discard """
errormsg: "'+' cannot be passed to a procvar"
line: 8
"""

# bug #2050

let v: proc (a, b: int): int = `+`
