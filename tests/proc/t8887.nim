discard """
cmd: "nim check --hints:off $file"
errormsg: "'a' cannot be both 'var' and 'non-var'"
nimout: '''
t8887.nim(13, 8) Error: 'a' uses wrong syntax for a var typeclass; the syntax is 'var (T1 | T2)'; not 'var T1 | var T2'
t8887.nim(14, 8) Error: 'a' cannot be both 'var' and 'non-var'
t8887.nim(15, 8) Error: 'a' cannot be both 'var' and 'non-var'
t8887.nim(16, 8) Error: 'a' cannot be both 'var' and 'non-var'
t8887.nim(17, 8) Error: 'a' cannot be both 'var' and 'non-var'
'''
"""

proc x(a: var float | var int) = discard
proc y(a: var float | int) = discard
proc z(a: float | var int) = discard
proc t(a: var float | int | bool) = discard
proc u(a: float | int | var bool) = discard
