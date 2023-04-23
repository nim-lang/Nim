discard """
errormsg: "conversion from int literal(1000000) to range 0..255(int) is invalid"
line: 6
"""

let a = {1_000_000} # Compiles
