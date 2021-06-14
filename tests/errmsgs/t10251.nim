discard """
errormsg: "redefinition of 'foo'; previous declaration here: t10251.nim(9, 9)"
line: 11
column: 9
"""

type
    Enum1 = enum
        foo, bar, baz
    Enum2 = enum
        foo, bar, baz

