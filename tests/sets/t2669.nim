discard """
line: 6
errormsg: "cannot convert 6 to range 1..5(int8)"
"""

var c: set[range[1i8..5i8]] = {1i8, 2i8, 6i8}
