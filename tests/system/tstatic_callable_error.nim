# bug #16987

discard """
errormsg: "cannot evaluate at compile time: inp"
nimout: '''
tstatic_callable_error.nim(14, 21) Error: cannot evaluate at compile time: inp'''
"""


# line 10
proc getNum(a: int): int = a

let inp = 123
echo (static getNum(inp))
