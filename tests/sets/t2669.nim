discard """
errormsg: "cannot convert 6 to range 1..5(int8)"
line: 6
"""

var c: set[range[1i8..5i8]] = {1i8, 2i8, 6i8}
